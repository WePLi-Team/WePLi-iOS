import Foundation

// REQ-039 · UI-8d — 1위 예측. 후보 · 비율 · 확정 · 적중 기록은 서버 값(DEC-004)

public struct TopPrediction: Equatable, Sendable {
  public struct Option: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    /// 다른 사람들의 예측 비율(%)
    public let percent: Int

    public init(id: String, title: String, percent: Int) {
      self.id = id
      self.title = title
      self.percent = percent
    }
  }

  public struct Record: Equatable, Sendable {
    public let predictions: Int
    public let hits: Int
    /// 연속 적중
    public let streak: Int

    public init(predictions: Int, hits: Int, streak: Int) {
      self.predictions = predictions
      self.hits = hits
      self.streak = streak
    }
  }

  public let relayID: String
  /// 「첫 사랑이 생각나는 노래 모음」
  public let relayTitle: String
  /// 「1일 12시간」
  public let remaining: String
  public let options: [Option]
  /// 확정한 예측 — 바꿀 수 없다
  public var lockedID: Option.ID?
  public let record: Record

  public var locked: Option? {
    self.lockedID.flatMap { id in self.options.first { $0.id == id } }
  }

  public init(
    relayID: String,
    relayTitle: String,
    remaining: String,
    options: [Option],
    lockedID: Option.ID? = nil,
    record: Record
  ) {
    self.relayID = relayID
    self.relayTitle = relayTitle
    self.remaining = remaining
    self.options = options
    self.lockedID = lockedID
    self.record = record
  }
}

/// 「지금까지 8번 예측해서 **5번** 맞혔어요 · 2번 연속 적중 중」 — 맞힌 횟수만 굵다
public struct TopPredictionRecordText: Equatable {
  public let lead: String
  public let hits: String
  public let tail: String

  /// 처음이면 nil
  public init?(_ record: TopPrediction.Record) {
    guard record.predictions > 0 else { return nil }
    self.lead = "지금까지 \(record.predictions)번 예측해서 "
    self.hits = "\(record.hits)번"
    self.tail = " 맞혔어요" + (record.streak > 1 ? " · \(record.streak)번 연속 적중 중" : "")
  }

  public init(lead: String, hits: String, tail: String) {
    self.lead = lead
    self.hits = hits
    self.tail = tail
  }
}
