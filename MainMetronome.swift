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
    @State private var currentBeat: Int = 1
    @State private var timeSignature: Int = 4
    @State private var accentedBeats: Set<Int> = [1]
    
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
        if accentedBeats.contains(currentBeat) {
            accentPlayer?.play()
        } else {
            clickPlayer?.play()
        }
        currentBeat += 1
        if currentBeat > timeSignature {
            currentBeat = 1
        }
    }
    
    var beatInterval: TimeInterval {
        60.0/tempo
    }
    
    private let itemsPerRow = 8
    
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
                    ForEach(0..<(timeSignature + itemsPerRow - 1) / itemsPerRow, id: \.self) {row in
                        HStack(spacing: 8) {
                            ForEach(Array((row * itemsPerRow + 1)...min((row + 1) * itemsPerRow, timeSignature)), id: \.self) {beat in
                                Circle()
                                    .fill(
                                        (beat == (currentBeat == 1 ? timeSignature : currentBeat - 1) && isPlaying) ? Color.blue :
                                            accentedBeats.contains(beat) ? Color.white : Color.gray
                                    )
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
            }
        }
        .padding()
    }
    .onAppear {
        setupAudio()
    }
    .onDisappear {
        stopMetronome()
    }
}

#Preview {
    MainMetronome()
}
