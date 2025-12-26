//
//  SettingsView.swift
//  Metronom
//
//  Created by Thomas Hansson on 2025-12-10.
//

import SwiftUI

struct SettingsView: View {
    @Binding var timeSignature: Int
    @Binding var subdivision: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Settings")
                .font(.largeTitle)
                .foregroundStyle(.white)
            Text("Time Signature")
                .foregroundStyle(.white)
            HStack (spacing: 40) {
                Button {
                    if timeSignature > 1 {
                        timeSignature -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                }
                Text("\(timeSignature)")
                    .foregroundStyle(.white)
                    .font(.title)
                Button {
                    if timeSignature < 13 {
                        timeSignature += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                }
            }
            Text("Subdivision")
                .foregroundStyle(.white)
            HStack (spacing: 40) {
                Button {
                    if subdivision > 1 {
                        subdivision -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                }
                Text("\(subdivision)")
                    .foregroundStyle(.white)
                    .font(.title)
                Button {
                    if subdivision < 7 {
                        subdivision += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red:0.17, green:0.17, blue:0.18))
    }
}

#Preview {
    SettingsView(timeSignature: .constant(4), subdivision: .constant(1))
}
