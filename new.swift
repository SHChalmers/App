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
    
    var clickPlayer: AVAudioPlayer?
    var accentPlayer: AVAudioPlayer?
    var lowerPlayer: AVAudioPlayer?
    
    private init() {
        setupAudio()
    }
    
    private func setupAudio() {
        guard let url = Bundle.main.url(forResource: "tone-800", withExtension: "wav") else { return }
        do {
            clickPlayer = try AVAudioPlayer(contentsOf: url)
            clickPlayer?.prepareToPlay()
        } catch {
            print("Error loading sound: \(error)")
        }
        guard let accenturl = Bundle.main.url(forResource: "tone-1000", withExtension: "wav") else { return }
        do {
            accentPlayer = try AVAudioPlayer(contentsOf: accenturl)
            accentPlayer?.prepareToPlay()
        } catch {
            print("Error loading sound: \(error)")
        }
        guard let lowerurl = Bundle.main.url(forResource: "tone-800lower", withExtension: "wav") else { return }
        do {
            lowerPlayer = try AVAudioPlayer(contentsOf: lowerurl)
            lowerPlayer?.prepareToPlay()
        } catch {
            print("Error loading sound: \(error)")
        }
    }
    
    func playClick() {
        clickPlayer?.play()
    }
    
    func playAccent() {
        accentPlayer?.play()
    }
    
    func playLower() {
        lowerPlayer?.play()
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
                .frame(width: .infinity, height: 100)
                
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
    let bpm: Int
    let name: String
}

struct RudimentList: View {
    @State private var rudiments: [Rudiment] = []
    @State private var showingMenu: Bool = false
    @State private var selectedCategory: String = "Single Beat Combinations"
    
    var categories: [String] {
        Array(Set(rudiments.map { $0.category })).sorted()
    }
    
    var sortedRudiments: [Rudiment] {
        if selectedCategory.isEmpty {
            return rudiments
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
                        Spacer()
                        Button("Category") {
                            showingMenu = true
                        }
                        .padding(.trailing, 45)
                        .confirmationDialog("Select Category", isPresented: $showingMenu) {
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
                            NavigationLink(destination: RudimentPractice(rudiment: binding(for: rudiment))) {
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
                                }
                            }
                            .listRowBackground(Color(red: 0.11, green: 0.11, blue: 0.12))
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
        guard let url = Bundle.main.url(forResource: "rudiments", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Rudiment].self, from: data) else {
            print("Failed to load rudiments")
            return
        }
        rudiments = decoded
    }
}

struct RudimentPractice: View {
    @Binding var rudiment: Rudiment
    @State var isPlaying: Bool = false
    @State private var timer: Timer?
    @State private var currentBeat: Int = 1
    @State private var tempo: Double = 60
    @Environment(\.dismiss) private var dismiss
    
    private let audioManager = AudioManager.shared
    var body: some View {
        ZStack {
            Color(red:0.11, green:0.11, blue:0.12)
                .ignoresSafeArea()
            VStack {
                Text("\(Int(tempo))")
                    .foregroundStyle(.white)
                    .font(.system(size: 50))
                Slider(value: $tempo, in: 30...300)
                    .onChange(of: tempo) {
                        if isPlaying {
                            stopMetronome()
                            isPlaying = false
                        }
                    }
                    .padding(.horizontal)
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
