//
//  MainMetronome.swift
//  Metronom
//
//  Created by Simon Hansson on 2025-12-04.
//
import AVFoundation
import SwiftUI

struct MainMetronome: View {
    @State var tempo: Double = 60.0
    @State var isPlaying: Bool = false
    @State private var timer: Timer?
    @State private var clickPlayer: AVAudioPlayer?
    @State private var accentPlayer: AVAudioPlayer?
    @State private var lowerPlayer: AVAudioPlayer?
    @State private var currentBeat: Int = 1
    @State private var currentSub: Int = 0
    @State private var timeSignature: Int = 4
    @State private var subdivision: Int = 1
    @State private var accentedBeats: Set<Int> = [1]
    @State private var showSettings: Bool = false
    @State private var showFullscreen: Bool = false
    
    func setupAudio() {
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
                accentPlayer?.play()
            } else {
                clickPlayer?.play()
            }
            currentBeat += 1
            if currentBeat > timeSignature {
                currentBeat = 1
            }
            
        } else {
            lowerPlayer?.play()
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
        NavigationStack {
            ZStack {
                Color(red: showFullscreen ? 0 : 0.11, green: showFullscreen ? 0 : 0.11, blue: showFullscreen ? 0 : 0.12)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: showFullscreen ? 0.05 : 0.4).delay(showFullscreen ? 0 : 0.3), value: showFullscreen)
                VStack {
                    Text("\(Int(tempo))")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
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
            
            .onAppear {
                setupAudio()
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
}

#Preview {
    MainMetronome()
}
