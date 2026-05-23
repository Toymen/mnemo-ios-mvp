import AVFoundation
import Speech

@MainActor
@Observable
final class SpeechRecognizer {
    enum State: Equatable {
        case idle
        case requesting
        case recording
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var transcript: String = ""

    var isRecording: Bool { state == .recording }

    @ObservationIgnored var onSilenceSegment: ((String) -> Void)?

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var accumulatedText: String = ""
    private var currentSegment: String = ""

    private let silenceThreshold: TimeInterval = 4.0
    private let minimumSegmentLength = 10

    var locale: Locale = Locale(identifier: "en-US") {
        didSet {
            if locale != oldValue {
                lazySpeechRecognizer = nil
            }
        }
    }

    private var lazySpeechRecognizer: SFSpeechRecognizer?
    private var speechRecognizer: SFSpeechRecognizer? {
        if lazySpeechRecognizer == nil {
            lazySpeechRecognizer = SFSpeechRecognizer(locale: locale)
        }
        return lazySpeechRecognizer
    }

    func startRecording() {
        guard state != .recording else { return }
        state = .requesting
        transcript = ""
        accumulatedText = ""
        currentSegment = ""

        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch authStatus {
                case .authorized:
                    self.beginCapture()
                case .denied:
                    self.state = .error("Speech recognition permission denied. Enable it in Settings.")
                case .restricted:
                    self.state = .error("Speech recognition is restricted on this device.")
                case .notDetermined:
                    self.state = .error("Speech recognition authorization not determined.")
                @unknown default:
                    self.state = .error("Speech recognition unavailable.")
                }
            }
        }
    }

    func stopRecording() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        if state == .recording {
            if !currentSegment.isEmpty {
                appendToAccumulated(currentSegment)
                currentSegment = ""
            }
            transcript = accumulatedText
            state = .idle
        }
    }

    func clearTranscript() {
        accumulatedText = ""
        currentSegment = ""
        transcript = ""
    }

    // MARK: - Private

    private func appendToAccumulated(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if accumulatedText.isEmpty {
            accumulatedText = trimmed
        } else {
            accumulatedText += " " + trimmed
        }
    }

    private func updateTranscript() {
        if accumulatedText.isEmpty {
            transcript = currentSegment
        } else if currentSegment.isEmpty {
            transcript = accumulatedText
        } else {
            transcript = accumulatedText + " " + currentSegment
        }
    }

    private func beginCapture() {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            state = .error("Speech recognizer is not available for the current locale.")
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            state = .error("Could not configure audio session: \(error.localizedDescription)")
            return
        }

        let engine = AVAudioEngine()
        self.audioEngine = engine

        guard startRecognitionTask() else {
            state = .error("Could not start speech recognition.")
            return
        }

        do {
            try engine.start()
        } catch {
            state = .error("Audio engine failed to start: \(error.localizedDescription)")
            return
        }

        state = .recording
        resetSilenceTimer()
    }

    private func startRecognitionTask() -> Bool {
        guard let engine = audioEngine, let speechRecognizer else { return false }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            return false
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        self.recognitionRequest = request

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let result {
                    self.currentSegment = result.bestTranscription.formattedString
                    self.updateTranscript()
                    self.resetSilenceTimer()
                }

                if (result?.isFinal ?? false) || error != nil {
                    self.commitSegmentAndRestart()
                }
            }
        }

        return true
    }

    private func commitSegmentAndRestart() {
        guard state == .recording else { return }
        if !currentSegment.isEmpty {
            appendToAccumulated(currentSegment)
            currentSegment = ""
            updateTranscript()
        }
        restartRecognition()
    }

    private func restartRecognition() {
        guard state == .recording else { return }

        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        guard startRecognitionTask() else {
            stopRecording()
            return
        }
        resetSilenceTimer()
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSilence()
            }
        }
    }

    private func handleSilence() {
        guard state == .recording else { return }

        if !currentSegment.isEmpty {
            appendToAccumulated(currentSegment)
            currentSegment = ""
        }

        let text = accumulatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= minimumSegmentLength else { return }

        let savedText = text
        accumulatedText = ""
        transcript = ""

        onSilenceSegment?(savedText)
        restartRecognition()
    }
}
