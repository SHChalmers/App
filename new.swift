//
//  MainMetronome.swift
//  Metronom
//
//  Created by Simon Hansson on 2025-12-04.
//
import AVFoundation
import SwiftUI

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var engine = AVAudioEngine()
    private var player = AVAudioPlayerNode()
    private var clickBuffer: AVAudioPCMBuffer!
    private var accentBuffer: AVAudioPCMBuffer!
    private var lowerBuffer: AVAudioPCMBuffer!
    private var format: AVAudioFormat!
    
    private init() {
        setupAudio()
    }
    
    private func setupAudio() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        guard let url = Bundle.main.url(forResource: "tone-800", withExtension: "wav") else { return }
        do {
            let file = try AVAudioFile(forReading: url)
            format = file.processingFormat
            let frameCount = AVAudioFrameCount(min(UInt64(file.length), UInt64(UInt32.max)))
            clickBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try file.read(into: clickBuffer)
            clickBuffer.frameLength = frameCount
        } catch { print("Error loading click: \(error)"); return }
        
        guard let accentUrl = Bundle.main.url(forResource: "tone-1000", withExtension: "wav") else { return }
        do {
            let file = try AVAudioFile(forReading: accentUrl)
            let frameCount = AVAudioFrameCount(min(UInt64(file.length), UInt64(UInt32.max)))
            accentBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try file.read(into: accentBuffer)
            accentBuffer.frameLength = frameCount
        } catch { print("Error loading accent: \(error)"); return }
        
        guard let lowerUrl = Bundle.main.url(forResource: "tone-800lower", withExtension: "wav") else { return }
        do {
            let file = try AVAudioFile(forReading: lowerUrl)
            let frameCount = AVAudioFrameCount(min(UInt64(file.length), UInt64(UInt32.max)))
            lowerBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
            try file.read(into: lowerBuffer)
            lowerBuffer.frameLength = frameCount
        } catch { print("Error loading lower: \(error)"); return }
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.prepare()
        do { try engine.start() } catch { print("Engine start error: \(error)"); return }
        player.play()
    }
    
    func playClick() {
        player.scheduleBuffer(clickBuffer, at: nil, options: [], completionHandler: nil)
    }
    
    func playAccent() {
        player.scheduleBuffer(accentBuffer, at: nil, options: [], completionHandler: nil)
    }
    
    func playLower() {
        player.scheduleBuffer(lowerBuffer, at: nil, options: [], completionHandler: nil)
    }
}

struct BarView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                MainMetronome()
                    .tag(0)
                RudimentList()
                    .tag(1)
            }
            //.tabViewStyle(.page(indexDisplayMode: .never))
            
            VStack {
                Spacer()
                HStack() {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            selectedTab = 0
                        }
                    }) {
                        Image(systemName: "metronome.fill")
                            .font(.system(size:30))
                            .foregroundColor(selectedTab == 0 ? .blue : .white)
                    }
                    Spacer()
                    Button(action: {
                        withAnimation {
                            selectedTab = 1
                        }
                    }) {
                        Image(systemName: "music.note.list")
                            .font(.system(size:30))
                            .foregroundColor(selectedTab == 1 ? .blue : .white)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .frame(alignment: .center)
                .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            // Initialize audio manager on app launch
            _ = AudioManager.shared
        }
    }
}

struct MainMetronome: View {
    @State var tempo: Double = 60.0
    @State var isPlaying: Bool = false
    @State private var timer: Timer?
    @State private var currentBeat: Int = 1
    @State private var currentSub: Int = 0
    @State private var timeSignature: Int = 4
    @State private var subdivision: Int = 1
    @State private var accentedBeats: Set<Int> = [1]
    @State private var showSettings: Bool = false
    @State private var showFullscreen: Bool = false
    
    private let audioManager = AudioManager.shared
    
    func startMetronome() {
        timer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) {_ in playClick()}
        playClick()
    }
    func stopMetronome() {
        currentBeat = 1
        currentSub = 0
        timer?.invalidate()
        timer = nil
    }
    func playClick() {
        let isBeat = currentSub == 0
        if isBeat {
            if accentedBeats.contains(currentBeat) {
                audioManager.playAccent()
            } else {
                audioManager.playClick()
            }
            currentBeat += 1
            if currentBeat > timeSignature {
                currentBeat = 1
            }
            
        } else {
            audioManager.playLower()
        }
        currentSub += 1
        if currentSub >= subdivision {
            currentSub = 0
        }
    }
    
    var beatInterval: TimeInterval {
        60.0/(tempo * Double(subdivision))
    }
    
    private let itemsPerRow = 8
    
    var numberOfRows: Int {
        (timeSignature + itemsPerRow - 1) / itemsPerRow
    }
    
    func beatsForRow(_ row: Int) -> [Int] {
        let start = row * itemsPerRow + 1
        let end = min((row + 1) * itemsPerRow, timeSignature)
        return Array(start...end)
    }
    
    func circleColor(for beat: Int) -> Color {
        let displayedBeat = currentBeat == 1 ? timeSignature : currentBeat - 1
        if beat == displayedBeat && isPlaying {
            return Color.blue
        } else if accentedBeats.contains(beat) {
            return Color.white
        } else {
            return Color.gray
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: showFullscreen ? 0 : 0.11, green: showFullscreen ? 0 : 0.11, blue: showFullscreen ? 0 : 0.12)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: showFullscreen ? 0.05 : 0.4).delay(showFullscreen ? 0 : 0.3), value: showFullscreen)
            VStack {
                Text("\(Int(tempo))")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                
                Slider(value: $tempo, in: 30...300)
                    .onChange(of: tempo) {
                        if isPlaying {
                            stopMetronome()
                            isPlaying = false
                        }
                    }
                    .padding(.horizontal)
                VStack(spacing: 10) {
                    ForEach(0..<numberOfRows, id: \.self) {row in
                        HStack(spacing: 8) {
                            ForEach(beatsForRow(row), id: \.self) {beat in
                                Circle()
                                    .fill(circleColor(for: beat))
                                    .frame(width:30, height:30)
                                    .onTapGesture {
                                        if accentedBeats.contains(beat) {
                                            accentedBeats.remove(beat)
                                        } else {
                                            accentedBeats.insert(beat)
                                        }
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100)
                
                Button {
                    isPlaying.toggle()
                    if isPlaying {
                        startMetronome()
                    } else {
                        stopMetronome()
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                }
                .frame(width: 60, height:60)
                
                HStack(spacing: 30) {
                    Button {
                        showSettings = true
                        isPlaying = false
                        stopMetronome()
                    } label: {
                        Image(systemName:"gearshape.fill")
                    }
                    Button {
                        showFullscreen = true
                    } label: {
                        Image(systemName:"arrow.up.left.and.arrow.down.right")
                    }
                }
                .padding()
                .font( .title)
                .foregroundStyle(.white)
            }
            .padding()
        }
        .onDisappear {
            stopMetronome()
            isPlaying = false
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(timeSignature: $timeSignature, subdivision: $subdivision)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenMetronome(currentBeat: $currentBeat, timeSignature: $timeSignature, isPlaying: $isPlaying, startMetronome: startMetronome, stopMetronome: stopMetronome)
        }
    }
}

struct Rudiment: Identifiable, Codable {
    let id: Int
    let category: String
    var bpm: Int
    let name: String
    var favorite: Bool
}

struct RudimentList: View {
    @State private var rudiments: [Rudiment] = []
    @State private var showingMenu: Bool = false
    @State private var selectedCategory: String = "Favorites"
    
    var categories: [String] {
        // Preserve original JSON order by using first occurrence
        var seen = Set<String>()
        return rudiments.compactMap { rudiment in
            guard !seen.contains(rudiment.category) else { return nil }
            seen.insert(rudiment.category)
            return rudiment.category
        }
    }
    
    var sortedRudiments: [Rudiment] {
        if selectedCategory.isEmpty {
            return rudiments
        } else if selectedCategory == "Favorites" {
            return rudiments.filter { $0.favorite == true}
        } else {
            return rudiments.filter { $0.category == selectedCategory }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.11, green: 0.11, blue: 0.12)
                    .ignoresSafeArea()
                VStack {
                    HStack {
                        Button(selectedCategory) {
                            showingMenu = true
                        }
                        .padding(15)
                        .confirmationDialog("Select Category", isPresented: $showingMenu) {
                            Button("Favorites") {
                                selectedCategory = "Favorites"
                            }
                            ForEach(categories, id: \.self) { category in
                                Button(category) {
                                    selectedCategory = category
                                }
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                    }
                    List {
                        ForEach(sortedRudiments) { rudiment in
                            NavigationLink(destination: RudimentPractice(rudiment: binding(for: rudiment), onSave: saveRudiments)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(rudiment.name)
                                            .foregroundColor(.white)
                                        Text(rudiment.category)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text(String(rudiment.bpm))
                                        .foregroundColor(.white)
                                    Button {
                                        if let index = rudiments.firstIndex(where: { $0.id == rudiment.id }) {
                                            rudiments[index].favorite.toggle()
                                            saveRudiments()
                                        }
                                    } label: {
                                        Image(systemName: rudiment.favorite ? "star.fill" : "star")
                                            .foregroundColor(rudiment.favorite ? .yellow : .gray)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                            .listRowBackground(Color(red: 0.14, green: 0.14, blue: 0.15))
                            .foregroundStyle(.blue)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .onAppear {
                loadRudiments()
            }
        }
    }
    
    private func binding(for rudiment: Rudiment) -> Binding<Rudiment> {
        guard let index = rudiments.firstIndex(where: { $0.id == rudiment.id }) else {
            fatalError("Rudiment not found")
        }
        return $rudiments[index]
    }
    
    func loadRudiments() {
        // Try to load from Documents directory first (user-modified version)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("rudiments.json")
        
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Rudiment].self, from: data) {
            rudiments = decoded
            return
        }
        
        // Fall back to bundle if no user-modified version exists
        guard let url = Bundle.main.url(forResource: "rudiments", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Rudiment].self, from: data) else {
            print("Failed to load rudiments")
            return
        }
        rudiments = decoded
    }
    
    func saveRudiments() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("rudiments.json")
        
        if let encoded = try? JSONEncoder().encode(rudiments) {
            try? encoded.write(to: fileURL)
        }
    }
}

struct RudimentPractice: View {
    @Binding var rudiment: Rudiment
    @State var isPlaying: Bool = false
    @State private var timer: Timer?
    @State private var currentBeat: Int = 1
    @State private var tempo: Double = 60
    @Environment(\.dismiss) private var dismiss
    var onSave: (() -> Void)?
    
    private let audioManager = AudioManager.shared
    var body: some View {
        ZStack {
            Color(red:0.11, green:0.11, blue:0.12)
                .ignoresSafeArea()
            VStack {
                Text("\(Int(tempo))")
                    .foregroundStyle(.white)
                    .font(.system(size: 50))
                HStack {
                    Button {
                        tempo -= 1
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                    }
                    Slider(value: $tempo, in: 30...300)
                        .onChange(of: tempo) {
                            if isPlaying {
                                stopMetronome()
                                isPlaying = false
                            }
                        }
                        .padding(.horizontal)
                    Button {
                        tempo += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                }
                .padding()
                Button {
                    isPlaying.toggle()
                    if isPlaying {
                        startMetronome()
                    } else {
                        stopMetronome()
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                }
                .frame(width: 60, height:60)
                
                Button {
                    rudiment.bpm = Int(tempo)
                    onSave?()
                } label: {
                    Text("Set")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            VStack {
                HStack {
                    Button(action: { dismiss()
                        stopMetronome()
                        isPlaying = false }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
            VStack {
                Text(rudiment.category)
                    .foregroundStyle(.gray)
                    .font(.system(size:15))
                Text(rudiment.name)
                    .foregroundStyle(.white)
                    .font(.system(size:20))
                Spacer()
            }
            .padding()
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tempo = Double(rudiment.bpm)
        }
        .onDisappear {
            isPlaying = false
            stopMetronome()
        }
    }
    func startMetronome() {
        timer = Timer.scheduledTimer(withTimeInterval: beatInterval, repeats: true) {_ in playClick()}
        playClick()
    }
    func stopMetronome() {
        currentBeat = 1
        timer?.invalidate()
        timer = nil
    }
    func playClick() {
        if currentBeat == 1 {
            audioManager.playAccent()
        } else {
            audioManager.playClick()
        }
        if currentBeat > 3 {
            currentBeat = 1
        } else {
            currentBeat += 1
        }
    }
    var beatInterval: TimeInterval {
        60.0/(tempo)
    }
}

#Preview {
    BarView()
}
