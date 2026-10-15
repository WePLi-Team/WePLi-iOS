import ComposableArchitecture
import SwiftUI

// REQ-114 · UI-7g — 앱 정보 · 약관 및 정책 · (숨김) 개발자 모드

struct AppInfoView: View {
  let store: StoreOf<AppInfoFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 0) {
        self.navigationBar
        ScrollView {
          if let document = self.store.document {
            self.documentView(document)
          } else {
            self.root
          }
        }
      }
      .background(WePLiColor.background.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .overlay(alignment: .top) { self.toastView() }
      .animation(.easeOut(duration: 0.2), value: self.store.toast)
      .onAppear { self.store.send(.onAppear) }
    }
  }

  private var navigationBar: some View {
    ZStack {
      // 원본은 문서 본문에서 제목을 비운다
      Text(self.store.document == nil ? "앱 정보" : "")
        .wepliFont(.button)
        .foregroundStyle(WePLiColor.textPrimary)
        .accessibilityAddTraits(.isHeader)
      HStack {
        WePLiIconButton(systemName: "chevron.left", accessibilityLabel: "뒤로") { self.store.send(.backButtonTapped) }
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
  }

  @ViewBuilder
  private func toastView() -> some View {
    if let toast = self.store.toast {
      Text(toast)
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.textPrimary)
        .lineLimit(1)
        .padding(.horizontal, 18)
        .frame(height: WePLiToast.height)
        .wepliGlass(in: Capsule())
        .padding(.top, 58)
        .transition(.opacity)
        .accessibilityAddTraits(.updatesFrequently)
    }
  }

  private var root: some View {
    VStack(spacing: 0) {
      self.header.padding(.top, 24)
      VStack(alignment: .leading, spacing: 24) {
        self.group("약관 및 정책") {
          ForEach(AppDocument.all) { document in
            self.documentRow(document)
          }
        }
        if self.store.isDeveloperModeEnabled {
          self.developerGroup
        }
        VStack(alignment: .leading, spacing: 4) {
          // 미결정 — 문의 주소 · 사업자 정보는 출시 전에 정한다(원본 예시)
          Text("위플리 · 문의 support@wepli.app (예시)")
          Text("사업자 정보는 출시 전에 채워 넣어야 해요")
        }
        .wepliFont(.caption)
        .foregroundStyle(WePLiColor.textDisabled)
        .padding(.horizontal, 16)
      }
      .padding(.horizontal, 16)
      .padding(.top, 26)
      .padding(.bottom, 60)
    }
  }

  private var header: some View {
    VStack(spacing: 8) {
      Button {
        self.store.send(.versionTapped)
      } label: {
        // 미결정 — 로고 에셋이 없어 글자로 자리 표시
        RoundedRectangle(cornerRadius: 20)
          .fill(WePLiColor.background)
          .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
          .overlay {
            Text("W").font(.custom(WePLiFont.Weight.bold.postScriptName, size: 30, relativeTo: .title))
              .foregroundStyle(WePLiColor.accent)
          }
          .frame(width: 84, height: 84)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("WePLi 앱 아이콘")
      Text("WePLi").wepliFont(.title3, weight: .bold).foregroundStyle(WePLiColor.textPrimary).padding(.top, 6)
      Button("버전 \(self.store.version)") { self.store.send(.versionTapped) }
        .wepliFont(.subheadline)
        .foregroundStyle(WePLiColor.textQuaternary)
      if let update = self.store.update {
        Button("\(update) 업데이트하기") { self.store.send(.updateTapped) }
          .wepliFont(.subheadline, weight: .semibold)
          .foregroundStyle(WePLiColor.accent)
          .padding(.horizontal, 16)
          .frame(height: 36)
          .background(WePLiColor.chipOn, in: Capsule())
          .padding(.top, 6)
      }
    }
    .frame(maxWidth: .infinity)
  }

  private func group(_ title: String, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .wepliFont(.footnote)
        .foregroundStyle(WePLiColor.textQuaternary)
        .padding(.horizontal, 16)
        .accessibilityAddTraits(.isHeader)
      VStack(spacing: 0) { content() }
        .background(WePLiColor.surface1, in: RoundedRectangle(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
  }

  private func documentRow(_ document: AppDocument) -> some View {
    Button {
      self.store.send(.documentTapped(document.id))
    } label: {
      HStack {
        Text(document.title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(WePLiColor.textDisabled)
      }
      .padding(.horizontal, 16)
      .frame(height: 52)
      .contentShape(Rectangle())
      .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5) }
    }
    .buttonStyle(.plain)
  }

  /// 원본은 값만 보여준다 — 서버 전환 · 마감 줄이기 · 토큰 복사 동작은 정해지면 잇는다
  private var developerGroup: some View {
    self.group("개발자 모드") {
      self.developerRow("서버", value: "Staging", color: WePLiColor.positive)
      self.developerRow("릴레이 마감 1분으로 줄이기", value: "끔", color: WePLiColor.textQuaternary)
      self.developerRow("푸시 토큰 복사", value: "복사", color: WePLiColor.accent, isLast: true)
    }
  }

  private func developerRow(_ title: String, value: String, color: Color, isLast: Bool = false) -> some View {
    HStack {
      Text(title).wepliFont(.body).foregroundStyle(WePLiColor.textPrimary)
      Spacer()
      Text(value).wepliFont(.body).foregroundStyle(color)
    }
    .padding(.horizontal, 16)
    .frame(height: 52)
    .overlay(alignment: .bottom) {
      if !isLast {
        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5)
      }
    }
    .accessibilityElement(children: .combine)
  }

  private func documentView(_ document: AppDocument) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(document.title).wepliFont(.title2).foregroundStyle(WePLiColor.textPrimary).accessibilityAddTraits(.isHeader)
      // 미결정 — 시행일 · 「이전 버전 보기」는 원본 예시(동작 없음)
      Text("시행일 2026.09.01 · 이전 버전 보기").wepliFont(.caption).foregroundStyle(WePLiColor.textQuaternary)
      ForEach(document.clauses, id: \.title) { clause in
        VStack(alignment: .leading, spacing: 6) {
          Text(clause.title).wepliFont(.body, weight: .semibold).foregroundStyle(WePLiColor.textPrimary)
          Text(clause.body).wepliFont(.subheadline).lineSpacing(5).foregroundStyle(WePLiColor.textSecondary)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.top, 16)
    .padding(.bottom, 60)
  }
}

#Preview {
  NavigationStack {
    AppInfoView(store: Store(initialState: AppInfoFeature.State()) { AppInfoFeature() })
  }
}
