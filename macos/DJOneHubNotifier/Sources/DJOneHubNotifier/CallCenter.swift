import Foundation
import Combine

/// 原生主窗口的数据中心：轮询后台 /api/calls/status，驱动拨号、通话与最近通话界面。
@MainActor
final class CallCenter: ObservableObject {
    @Published var activeCall: CallRecord?
    @Published var history: [CallRecord] = []
    @Published var isOnline = false
    @Published var lastError: String?
    @Published var isMuted = false
    @Published var isRecording = false
    @Published var numberInput = ""
    @Published var isDialing = false

    private let api: DJOneHubAPI
    var apiClient: DJOneHubAPI { api }
    private var pollTask: Task<Void, Never>?
    private var lastActiveID: String?
    private var pollInFlight = false

    /// 新来电（呼入且响铃/等待）时回调，用于弹窗/聚焦主窗口。
    var onIncoming: ((CallRecord) -> Void)?

    init(api: DJOneHubAPI) {
        self.api = api
    }

    func start() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollOnce()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func pollOnce() async {
        guard !pollInFlight else { return }
        pollInFlight = true
        defer { pollInFlight = false }
        do {
            let status = try await api.callStatus()
            isOnline = true
            lastError = status.lastPollError
            let previousID = activeCall?.id
            activeCall = status.active
            history = status.history ?? []

            if status.active == nil, previousID != nil, isRecording {
                _ = try? await api.setCallRecording(false)
                isRecording = false
            }

            if let active = status.active,
               active.direction == "incoming",
               active.state == "incoming" || active.state == "waiting",
               active.id != lastActiveID {
                lastActiveID = active.id
                onIncoming?(active)
            } else if status.active == nil {
                lastActiveID = nil
            }
            if status.active?.id != previousID, status.active == nil || previousID == nil {
                isMuted = false
            }
        } catch {
            isOnline = false
            lastError = error.localizedDescription
        }
    }

    func dial() {
        let number = numberInput.trimmingCharacters(in: .whitespaces)
        guard !number.isEmpty else { return }
        isDialing = true
        Task {
            do {
                try await api.dial(number: number)
                await MainActor.run {
                    self.isDialing = false
                }
            } catch {
                await MainActor.run {
                    self.isDialing = false
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func answer() {
        Task { _ = try? await api.answerCall() }
    }

    func reject() {
        Task { _ = try? await api.rejectCall() }
    }

    func hangup() {
        isMuted = false
        Task { _ = try? await api.hangupCall() }
    }

    func sendDTMF(_ digit: String) {
        Task { _ = try? await api.sendDTMF(digit: digit) }
    }

    func toggleMute() {
        let muted = !isMuted
        isMuted = muted
        Task { _ = try? await api.setAudioMuted(muted) }
    }

    func toggleRecording() {
        let target = !isRecording
        isRecording = target
        Task {
            do {
                _ = try await api.setCallRecording(target)
            } catch {
                await MainActor.run {
                    self.isRecording = !target
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func callDuration(now: Date = Date()) -> TimeInterval {
        guard let call = activeCall else { return 0 }
        let end = call.endedAt ?? now
        return max(0, end.timeIntervalSince(call.startedAt))
    }

    func dialNumber(_ number: String) {
        numberInput = number
        dial()
    }
}
