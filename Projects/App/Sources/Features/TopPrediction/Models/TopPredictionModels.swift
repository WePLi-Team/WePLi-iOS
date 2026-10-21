import Foundation

// REQ-039 · UI-8d — 1위 예측. 후보 · 비율 · 확정 · 적중 기록은 서버 값(DEC-004)

struct TopPrediction: Equatable, Sendable {
  struct Option: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    /// 다른 사람들의 예측 비율(%)
    let percent: Int
  }

  struct Record: Equatable, Sendable {
    let predictions: Int
    let hits: Int
    /// 연속 적중
    let streak: Int
  }

  let relayID: String
  /// 「첫 사랑이 생각나는 노래 모음」
  let relayTitle: String
  /// 「1일 12시간」
  let remaining: String
  let options: [Option]
  /// 확정한 예측 — 바꿀 수 없다
  var lockedID: Option.ID?
  let record: Record

  var locked: Option? {
    self.lockedID.flatMap { id in self.options.first { $0.id == id } }
  }
}

/// 「지금까지 8번 예측해서 **5번** 맞혔어요 · 2번 연속 적중 중」 — 맞힌 횟수만 굵다
struct TopPredictionRecordText: Equatable {
  let lead: String
  let hits: String
  let tail: String

  /// 처음이면 nil
  init?(_ record: TopPrediction.Record) {
    guard record.predictions > 0 else { return nil }
    self.lead = "지금까지 \(record.predictions)번 예측해서 "
    self.hits = "\(record.hits)번"
    self.tail = " 맞혔어요" + (record.streak > 1 ? " · \(record.streak)번 연속 적중 중" : "")
  }
}
