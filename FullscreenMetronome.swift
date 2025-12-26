//
//  FullscreenMetronome.swift
//  Metronom
//
//  Created by Thomas Hansson on 2025-12-10.
//

import SwiftUI

struct FullscreenMetronome: View {
    @Binding var currentBeat: Int
    @Binding var timeSignature: Int
    @Binding var isPlaying: Bool
    var startMetronome: () -> Void
    var stopMetronome: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var displayedBeat: Int {
        currentBeat == 1 ? timeSignature : currentBeat - 1
    }
    
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
            Text("\(isPlaying ? displayedBeat : 1)")
                .font(.system(size: 300, weight: .bold))
                .foregroundStyle(.white)
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
            )
        .onTapGesture {
            isPlaying.toggle()
            if isPlaying {
                startMetronome()
            } else {
                stopMetronome()
            }
        }
    }
}

#Preview {
    FullscreenMetronome(currentBeat: .constant(1), timeSignature: .constant(4), isPlaying: .constant(false), startMetronome: {}, stopMetronome: {})
}
