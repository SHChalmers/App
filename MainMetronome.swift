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
    @State private var timeSignature: Int = 4
    @State private var subdivision: Int = 1
    @State private var accentedBeats: Set<Int> = [1]
    @State private var showSettings: Bool = false
    @State private var quarterNote: Int = 1
    
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
        guard let lowerURL = Bundle.main.url(forResource: "tone-800lower", withExtension: "wav") else { return }
        do {
            lowerPlayer = try AVAudioPlayer(contentsOf: lowerURL)
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
        timer?.invalidate()
        timer = nil
    }
    func playClick() {
        print(currentBeat)
        if accentedBeats.contains(currentBeat) {
            accentPlayer?.play()
        } else if currentBeat % subdivision == 1 {
            clickPlayer?.play()
            quarterNote += 1
        } else {
            lowerPlayer?.play()
        }
        currentBeat += 1
        if currentBeat > timeSignature*subdivision {
            currentBeat = 1
        }
        if quarterNote > timeSignature {
            quarterNote = 1
        }
    }
    
    var beatInterval: TimeInterval {
        60.0/(tempo*Double(subdivision))
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
        let displayedBeat = quarterNote == 1 ? timeSignature : quarterNote - 1
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
            Color(red:0.17, green:0.17, blue:0.18)
                .ignoresSafeArea()
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
                
                HStack {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName:"gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
                .padding()
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
    }
}

#Preview {
    MainMetronome()
}
