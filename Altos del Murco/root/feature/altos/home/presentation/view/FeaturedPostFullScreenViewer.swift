//
//  FeaturedPostFullScreenViewer.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

import SwiftUI

struct FeaturedPostFullScreenViewer: View {
    let media: [FeaturedPostMedia]
    
    @State var selectedIndex: Int
    @State private var currentScale: CGFloat = 1

    @Environment(\.dismiss) private var dismiss

    @State private var verticalDismissOffset: CGFloat = 0

    private var backgroundOpacity: Double {
        let progress = min(abs(verticalDismissOffset) / 260, 1)
        return 1 - (progress * 0.5)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(Array(media.enumerated()), id: \.element.id) { index, item in
                    ZoomableRemoteImageView(
                        url: item.downloadURL,
                        onScaleChanged: { scale in
                            if selectedIndex == index {
                                currentScale = scale
                            }
                        }
                    )
                    .tag(index)
                    .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .offset(y: verticalDismissOffset)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .simultaneousGesture(
            dismissDragGesture,
            including: .subviews
        )
        .onChange(of: selectedIndex) { _, _ in
            currentScale = 1
            verticalDismissOffset = 0
        }
        .statusBarHidden()
    }

    private var dismissDragGesture: some Gesture {
        DragGesture(minimumDistance: 22, coordinateSpace: .local)
            .onChanged { value in
                guard currentScale <= 1.01 else { return }

                let vertical = value.translation.height
                let horizontal = value.translation.width

                let isMostlyVertical = abs(vertical) > abs(horizontal) * 1.35
                guard isMostlyVertical else { return }

                verticalDismissOffset = vertical
            }
            .onEnded { value in
                guard currentScale <= 1.01 else { return }

                let vertical = value.translation.height
                let predicted = value.predictedEndTranslation.height
                let horizontal = value.translation.width

                let isMostlyVertical = abs(vertical) > abs(horizontal) * 1.35

                guard isMostlyVertical else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        verticalDismissOffset = 0
                    }
                    return
                }

                let shouldDismiss =
                    abs(vertical) > 140 ||
                    abs(predicted) > 240

                if shouldDismiss {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        verticalDismissOffset = 0
                    }
                }
            }
    }
}
