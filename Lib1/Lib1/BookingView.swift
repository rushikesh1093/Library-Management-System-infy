//
//  BookingView.swift
//  Lib1
//
//  Created by admin12 on 18/04/25.
//

import SwiftUI

struct BookingView: View {
    var body: some View {
        VStack {
            Image(systemName: "calendar")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue)
            Text("Booking")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue.opacity(0.05))
        .navigationTitle("Booking")
    }
}
