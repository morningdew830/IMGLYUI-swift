import SwiftUI

struct CustomScrollIndicatorView: View {
  let scrollViewFrameHeight: CGFloat
  let scrollViewContentSizeHeight: CGFloat
  let scrollViewContentOffsetY: CGFloat

  let scrollViewDelegate: TimelineScrollViewDelegate

  @State var topPadding: CGFloat = 3
  @State var bottomPadding: CGFloat = 3

  @State private var transientLabelTimer: Timer?
  @State private var isScrollBarVisible = false

  @State private var handleHeight: CGFloat = 0
  @State private var handleOffset: CGFloat = 0

  var body: some View {
    ZStack {
      if isScrollBarVisible {
        RoundedRectangle(cornerRadius: 1.3)
          .fill(.secondary)
          .frame(width: 3)
          .frame(height: handleHeight)
          .offset(y: handleOffset)
          .padding(.trailing, 3)
          .transition(.opacity)
      }
    }
    .allowsHitTesting(false)
    .animation(isScrollBarVisible ? nil : .easeInOut(duration: 0.7), value: isScrollBarVisible)
    .onAppear {
      refresh(contentOffsetY: scrollViewContentOffsetY)
      Task {
        try await Task.sleep(for: .milliseconds(300))
        flashScrollBar()
      }
    }
    .onChange(of: scrollViewDelegate.contentOffset) { newValue in
      refresh(contentOffsetY: newValue.y)
      flashScrollBar()
    }
  }

  private func refresh(contentOffsetY: CGFloat) {
    let visibleHeight = scrollViewFrameHeight - topPadding - bottomPadding
    let contentSizeHeight = scrollViewContentSizeHeight
    let maxOffset = contentSizeHeight - visibleHeight
    let normalizedOffset = contentOffsetY / maxOffset
    let handleHeight = visibleHeight * (visibleHeight / contentSizeHeight)
    let bottomOvershoot = contentOffsetY - (contentSizeHeight - visibleHeight)

    let finalHandleHeight: CGFloat = if contentOffsetY < 0 {
      max(7, handleHeight + contentOffsetY)
    } else if contentOffsetY + visibleHeight > contentSizeHeight {
      max(7, handleHeight - bottomOvershoot)
    } else {
      handleHeight
    }

    let handleOffset = max(
      topPadding,
      min(
        visibleHeight - finalHandleHeight + topPadding,
        topPadding + (visibleHeight - finalHandleHeight) * normalizedOffset
      )
    )

    self.handleHeight = finalHandleHeight
    self.handleOffset = handleOffset
  }

  private func flashScrollBar() {
    isScrollBarVisible = true
    transientLabelTimer?.invalidate()
    transientLabelTimer = Timer.scheduledTimer(withTimeInterval: 1.15, repeats: false, block: { _ in
      isScrollBarVisible = false
    })
  }
}
