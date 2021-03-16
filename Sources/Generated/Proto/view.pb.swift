// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: view.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

// Copyright (c) 2018-2021 The MobileCoin Foundation

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

//// Corresponds to and documents values of TxOutSearchResult.result_code
//// If any values are added they must be synced with TxOutSearchResult used in recovery db
public enum FogView_TxOutSearchResultCode: SwiftProtobuf.Enum {
  public typealias RawValue = Int
  case intentionallyUnused // = 0

  //// A result was found
  case found // = 1

  //// A result was not found
  case notFound // = 2

  //// The search key is bad (e.g. wrong size) and the request could not be completed
  case badSearchKey // = 3

  //// An internal occurred (e.g. a database failed)
  case internalError // = 4

  //// The query was rate limited
  //// (the server decided not to service the query in order to satisfy a limit)
  case rateLimited // = 5
  case UNRECOGNIZED(Int)

  public init() {
    self = .intentionallyUnused
  }

  public init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .intentionallyUnused
    case 1: self = .found
    case 2: self = .notFound
    case 3: self = .badSearchKey
    case 4: self = .internalError
    case 5: self = .rateLimited
    default: self = .UNRECOGNIZED(rawValue)
    }
  }

  public var rawValue: Int {
    switch self {
    case .intentionallyUnused: return 0
    case .found: return 1
    case .notFound: return 2
    case .badSearchKey: return 3
    case .internalError: return 4
    case .rateLimited: return 5
    case .UNRECOGNIZED(let i): return i
    }
  }

}

#if swift(>=4.2)

extension FogView_TxOutSearchResultCode: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  public static var allCases: [FogView_TxOutSearchResultCode] = [
    .intentionallyUnused,
    .found,
    .notFound,
    .badSearchKey,
    .internalError,
    .rateLimited,
  ]
}

#endif  // swift(>=4.2)

//// There are several kinds of records returned by the fog view API
//// - RngRecords, which a user can use with their private key to construct KexRng's
//// - TxOutSearchResults, which the user can decrypt with their private key to obtain TxOutRecords
//// - Missed BlockRanges, which tell the user about blocks that fog didn't process,
////   on which they have to fallback to view key scanning. They can download these blocks
////   from the fog-ledger server.
////
//// The TxOut requests ultimately have to be served obliviously to the user in order to meet
//// our definition of privacy. The other two do not.
////
//// A QueryRequest is one request which can represent many logical requests for the above
//// kinds of records. The API is amalgamated in this way to reduce the number of round-trips
//// needed by the client. Note that QueryRequest is actually split into two Protobuf messages:
//// QueryRequest -  which contains sensitive data exchanged over an attested and encrypted connection
//// and QueryRequestAAD - which contains unsensitive data.
//// We split sensitive and unsensitive data since part of the request is fulfilled by untrusted code and part
//// is fulfilled by an enclave.
////
//// The API also supports an important optimization called "cursoring". This means that when
//// you make a request, you tell us "where you were when you visited the API last" and we can
//// avoid searching historical data to give you relevant updates.
////
//// There are two cursors to pay attention to:
//// - start_from_user_event_id - This cursors the events table, allowing the caller to skip events they have already received.
//// - start_from_block_index - This limits the set of blocks in which ETxOutRecords are searched, resulting in less load on the server.
////
//// Missed BlockRanges are reported to you based on whatever cursor value you supply.
//// RngRecords can only be supplied if you supply the user's public view key. We will skip that
//// if you don't.
//// TxOutSearchResults are supplied if you supply fog search keys (outputs from a kex rng) in the get_txos
//// field.
////
//// Example usage:
//// Typically when hitting fog view, you will make a series of requests, not just one.
//// The first one checks for new rng records, and later ones check for new txos in increasingly
//// large numbers, depending on how many responses come back, how many Rng's you have, etc.
////
//// QueryRequest { address_public_key = 0x123..., start_from_block_index = 100, start_from_user_event_id = 100 }
//// QueryRequest { get_txos = { 0x1..., 0x2... }, start_from... }
//// QueryRequest { get_txos = { 0x3..., 0x4..., 0x5..., 0x6.... , start_from...} }
//// QueryRequest { get_txos = { 0x7..., 0x8..., 0x9..., 0x10... , start_from...} }
////
//// It is possible to combine the first get_txos request with the address_public_key request
//// if you already have some Rng's before you make that request.
////
//// The highest_processed_block_count value from the first request in a given session should become the
//// start_from_block_index value the next time you make a request. Similarly, next_start_from_user_event_id should
//// become start_from_user_event_id for the next request.
////
/// After the interaction, you can be sure that you got every Txo of yours up to those cursor values.
////
//// An additional optimizaiton is possible: if doing full wallet recovery and you have no Rngs
//// at all, the request sequence might look like this:
////
//// QueryRequest { address_public_key = 0x123..., start_from_block_index = 0 }
//// QueryRequest { start_from_block_index = 73, get_txos = { 0x1..., 0x2... } }
//// QueryRequest { start_from_block_index = 73, get_txos = { 0x3..., 0x4..., 0x5..., 0x6.... } }
//// QueryRequest { start_from_block_index = 73, get_txos = { 0x7..., 0x8..., 0x9..., 0x10... } }
////
//// The first request has start_from_block_index = 0, and gives back all the Rng records of the user.
//// After inspecting those records, if there are no Rng's with start_block less than 73,
//// then start_from_block_index can be 73 for the rest of the requests, which limits the amount of
//// historical data that must be searched to support the requst.
public struct FogView_QueryRequestAAD {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  //// The last event id the client is aware of.
  public var startFromUserEventID: Int64 = 0

  //// The first block index to search TXOs in.
  public var startFromBlockIndex: UInt64 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

public struct FogView_QueryRequest {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  //// KexRng output bytes, "search keys", to request TxOutSearchResult's for
  public var getTxos: [Data] = []

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

//// When the result comes back, after decryption, the attest.Message plaintext
//// follows this schema
public struct FogView_QueryResponse {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  //// The number of blocks processed at the time that the request was evaluated.
  ////
  //// The semantics of the result as a whole are, we guarantee to get you all
  //// relevant event data from start_from_user_event_id to next_start_from_user_event_id
  //// and all TxOutSearchResults from start_from_block_index to highest_processed_block_count.
  ////
  //// The highest_processed_block_count value you had last time should generally be the start_from_block_index
  //// value next time, but there are caveats.
  ////
  //// If you have no data, start_from_block_index should be 0. Then you get your rng records,
  //// and start_from_block_index can be the minimum start block of any of your rng records.
  public var highestProcessedBlockCount: UInt64 = 0

  //// The timestamp of the block corresponding to highest_processed_block_count
  public var highestProcessedBlockSignatureTimestamp: UInt64 = 0

  //// The next value to use for start_from_user_event_id. For the first query, this should
  //// be 0.
  public var nextStartFromUserEventID: Int64 = 0

  //// Any block ranges that are missed.
  //// These ranges are guaranteed to be non-overlapping.
  //// The client should take these ranges to fog ledger and download them and scan them
  //// in order to recover any TxOut's from these ranges.
  ////
  //// FIXME: MC-1488 Don't tell users about missed blocks from before they had an RNG.
  //// Possibly, don't tell them about ANY missed blocks UNLESS they supply user_public
  //// It is expected to be omitted when they are making repeated follow-up
  //// "get_txos" queries.
  public var missedBlockRanges: [FogCommon_BlockRange] = []

  //// Any new rng records produced by the request
  public var rngs: [FogView_RngRecord] = []

  //// Any decommissioned ingest invocations
  public var decommissionedIngestInvocations: [FogView_DecommissionedIngestInvocation] = []

  //// Any TxOutSearchResults from the get_txos in the request.
  public var txOutSearchResults: [FogView_TxOutSearchResult] = []

  //// Extra data: The index of the last known block.
  //// This might be larger than highest_processed_block_count.
  //// This field doesn't have the same "cursor" semantics as the other fields.
  public var lastKnownBlockCount: UInt64 = 0

  //// Extra data: The cumulative txo count of the last known block.
  //// This can be used by the client as a hint when choosing cryptonote mixin indices.
  //// This field doesn't have the same "cursor" semantics as the other fields.
  public var lastKnownBlockCumulativeTxoCount: UInt64 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

//// A record of an Rng created by a fog ingest enclave.
//// This can be used with the user's private view key to construct ClientKexRng,
//// and get fog search keys.
public struct FogView_RngRecord {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  //// The ingest invocation id that produced this record.
  //// This is used to match against DecommissionedIngestInvocation objects when querying for new events.
  public var ingestInvocationID: Int64 = 0

  //// A key-exchange message to be used by the client to create a VersionedKexRng
  public var pubkey: KexRng_KexRngPubkey {
    get {return _pubkey ?? KexRng_KexRngPubkey()}
    set {_pubkey = newValue}
  }
  /// Returns true if `pubkey` has been explicitly set.
  public var hasPubkey: Bool {return self._pubkey != nil}
  /// Clears the value of `pubkey`. Subsequent reads from it will return its default value.
  public mutating func clearPubkey() {self._pubkey = nil}

  //// The start block (when fog started using this rng)
  public var startBlock: UInt64 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _pubkey: KexRng_KexRngPubkey? = nil
}

//// Information about a decommissioned ingest invocation.
public struct FogView_DecommissionedIngestInvocation {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  //// The ingest invocation id that was decommissioned.
  public var ingestInvocationID: Int64 = 0

  //// The last block index that was successfully ingested by this invocation.
  public var lastIngestedBlock: UInt64 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

//// The result of a search result for a TxOutRecord
public struct FogView_TxOutSearchResult {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  //// The search key associated to this result
  public var searchKey: Data = Data()

  //// The result code for the query.
  //// This is logically an enum, but should not be an enum because protobuf
  //// requires that enums are encoded using the "varint" encoding which is not fixed size.
  //// We want that e.g. "Found" and "NotFound" have the same length on the wire to avoid leaking that.
  //// So it is a fixed32 in protobuf, and the 0 (default) value is intentionally unused.
  public var resultCode: UInt32 = 0

  //// A ciphertext, which is a view-key encrypted TxOutRecord in case result_code == 1.
  //// It is be zero-padding in the other cases.
  //// FIXME: MC-1491 ensure this happens either in enclave or db, or wait for ORAM
  public var ciphertext: Data = Data()

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

//// A Redacted Fog Transaction Output.
//// This is the same as a normal TxOut, except that the fog hint is removed after processing, to save storage.
public struct FogView_FogTxOut {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  //// Amount.
  public var amount: External_Amount {
    get {return _amount ?? External_Amount()}
    set {_amount = newValue}
  }
  /// Returns true if `amount` has been explicitly set.
  public var hasAmount: Bool {return self._amount != nil}
  /// Clears the value of `amount`. Subsequent reads from it will return its default value.
  public mutating func clearAmount() {self._amount = nil}

  //// Public key.
  public var targetKey: External_CompressedRistretto {
    get {return _targetKey ?? External_CompressedRistretto()}
    set {_targetKey = newValue}
  }
  /// Returns true if `targetKey` has been explicitly set.
  public var hasTargetKey: Bool {return self._targetKey != nil}
  /// Clears the value of `targetKey`. Subsequent reads from it will return its default value.
  public mutating func clearTargetKey() {self._targetKey = nil}

  //// Public key.
  public var publicKey: External_CompressedRistretto {
    get {return _publicKey ?? External_CompressedRistretto()}
    set {_publicKey = newValue}
  }
  /// Returns true if `publicKey` has been explicitly set.
  public var hasPublicKey: Bool {return self._publicKey != nil}
  /// Clears the value of `publicKey`. Subsequent reads from it will return its default value.
  public mutating func clearPublicKey() {self._publicKey = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _amount: External_Amount? = nil
  fileprivate var _targetKey: External_CompressedRistretto? = nil
  fileprivate var _publicKey: External_CompressedRistretto? = nil
}

//// The schema for the decrypted TxOutSearchResult ciphertext
//// This is the information that the Ingest enclave produces for the user about their TxOut
////
//// Note: The fields of FogTxOut are flattened here because it reduces the size of the protobuf
//// enough to make a difference for the quality of ORAM implementation, like ~10% better memory utilization
////
//// Note: Fog TxOutRecord DOES NOT include the encrypted fog hint of the original TxOut, because it is big,
//// and the client cannot read it anyways. However, when using the TxOut to build transactions, you must have that
//// or the merkle proofs will fail validation, at least for now.
//// The fog merkle proof server gives you a TxOut with fog hint, as it appears in blockchain,
//// and that's the version of the TxOut that you should use when building a transaction.
public struct FogView_TxOutRecord {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  //// The (compressed ristretto) bytes of commitment associated to amount field in the TxOut that was recovered
  public var txOutAmountCommitmentData: Data = Data()

  //// The masked value associated to amount field in the TxOut that was recovered
  public var txOutAmountMaskedValue: UInt64 = 0

  //// The (compressed ristretto) bytes of the target key associated to the TxOut that was recovered
  public var txOutTargetKeyData: Data = Data()

  //// The (compressed ristretto) bytes of the public key associated to the TxOut that was recovered
  public var txOutPublicKeyData: Data = Data()

  //// The global index of this TxOut in the set of all TxOuts in the entire block chain
  public var txOutGlobalIndex: UInt64 = 0

  //// The index of the block index in which this TxOut appeared
  public var blockIndex: UInt64 = 0

  //// The timestamp of the block containing this output.
  //// Some blocks, like the origin block, don't have a timestamp, and this value is u64::MAX
  //// Other blocks are expected to have timestamps.
  ////
  //// Note: The timestamp is based on untrusted reporting of time from ONE of the consensus validators.
  //// Because it is a distributed system, it may not be the SAME consensus validator from block to block,
  //// and the timestamps may not make even a minimal amount of sense when the validator differs.
  ////
  //// These timestamps are
  //// - NOISY, forward and backwards in time, depending on system time settings of many different servers.
  //// - NOT MONOTONIC: it's possible that you get a timestamp for block 101 that is before the timestamp for block 100.
  //// - Not even CONSISTENT across fog services: It's possible you get a different timestamp for a TxOut in block 100,
  ////   than you do for a key image in block 100 from the key image endpoint.
  ////   This is unavoidable right now because it is possible that fog-ingest has different levels of
  ////   connectivity from the fog-key-image service to the blockchain data sources.
  ////
  //// Timestamps are BEST-EFFORT and for a good user experience, the client software should attempt to reconcile these
  //// timestamps, so that events that have a happens-before relationship in the system, have timestamps that reflect that.
  //// Otherwise, we should expect users to be confused and disturbed about the occasional time-travelling transaction.
  ////
  //// We hope to improve the quality guarantees of these timestamps over time, but for now this is the best we
  //// can do until some changes can be made to the consensus network and other services related to timestamps.
  ////
  //// Represented as seconds of UTC time since Unix epoch 1970-01-01T00:00:00Z.
  public var timestamp: UInt64 = 0

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "fog_view"

extension FogView_TxOutSearchResultCode: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "IntentionallyUnused"),
    1: .same(proto: "Found"),
    2: .same(proto: "NotFound"),
    3: .same(proto: "BadSearchKey"),
    4: .same(proto: "InternalError"),
    5: .same(proto: "RateLimited"),
  ]
}

extension FogView_QueryRequestAAD: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".QueryRequestAAD"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "start_from_user_event_id"),
    2: .standard(proto: "start_from_block_index"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt64Field(value: &self.startFromUserEventID) }()
      case 2: try { try decoder.decodeSingularUInt64Field(value: &self.startFromBlockIndex) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.startFromUserEventID != 0 {
      try visitor.visitSingularInt64Field(value: self.startFromUserEventID, fieldNumber: 1)
    }
    if self.startFromBlockIndex != 0 {
      try visitor.visitSingularUInt64Field(value: self.startFromBlockIndex, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: FogView_QueryRequestAAD, rhs: FogView_QueryRequestAAD) -> Bool {
    if lhs.startFromUserEventID != rhs.startFromUserEventID {return false}
    if lhs.startFromBlockIndex != rhs.startFromBlockIndex {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension FogView_QueryRequest: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".QueryRequest"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "get_txos"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedBytesField(value: &self.getTxos) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.getTxos.isEmpty {
      try visitor.visitRepeatedBytesField(value: self.getTxos, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: FogView_QueryRequest, rhs: FogView_QueryRequest) -> Bool {
    if lhs.getTxos != rhs.getTxos {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension FogView_QueryResponse: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".QueryResponse"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "highest_processed_block_count"),
    2: .standard(proto: "highest_processed_block_signature_timestamp"),
    3: .standard(proto: "next_start_from_user_event_id"),
    4: .standard(proto: "missed_block_ranges"),
    5: .same(proto: "rngs"),
    6: .standard(proto: "decommissioned_ingest_invocations"),
    7: .standard(proto: "tx_out_search_results"),
    8: .standard(proto: "last_known_block_count"),
    9: .standard(proto: "last_known_block_cumulative_txo_count"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt64Field(value: &self.highestProcessedBlockCount) }()
      case 2: try { try decoder.decodeSingularUInt64Field(value: &self.highestProcessedBlockSignatureTimestamp) }()
      case 3: try { try decoder.decodeSingularInt64Field(value: &self.nextStartFromUserEventID) }()
      case 4: try { try decoder.decodeRepeatedMessageField(value: &self.missedBlockRanges) }()
      case 5: try { try decoder.decodeRepeatedMessageField(value: &self.rngs) }()
      case 6: try { try decoder.decodeRepeatedMessageField(value: &self.decommissionedIngestInvocations) }()
      case 7: try { try decoder.decodeRepeatedMessageField(value: &self.txOutSearchResults) }()
      case 8: try { try decoder.decodeSingularUInt64Field(value: &self.lastKnownBlockCount) }()
      case 9: try { try decoder.decodeSingularUInt64Field(value: &self.lastKnownBlockCumulativeTxoCount) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.highestProcessedBlockCount != 0 {
      try visitor.visitSingularUInt64Field(value: self.highestProcessedBlockCount, fieldNumber: 1)
    }
    if self.highestProcessedBlockSignatureTimestamp != 0 {
      try visitor.visitSingularUInt64Field(value: self.highestProcessedBlockSignatureTimestamp, fieldNumber: 2)
    }
    if self.nextStartFromUserEventID != 0 {
      try visitor.visitSingularInt64Field(value: self.nextStartFromUserEventID, fieldNumber: 3)
    }
    if !self.missedBlockRanges.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.missedBlockRanges, fieldNumber: 4)
    }
    if !self.rngs.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.rngs, fieldNumber: 5)
    }
    if !self.decommissionedIngestInvocations.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.decommissionedIngestInvocations, fieldNumber: 6)
    }
    if !self.txOutSearchResults.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.txOutSearchResults, fieldNumber: 7)
    }
    if self.lastKnownBlockCount != 0 {
      try visitor.visitSingularUInt64Field(value: self.lastKnownBlockCount, fieldNumber: 8)
    }
    if self.lastKnownBlockCumulativeTxoCount != 0 {
      try visitor.visitSingularUInt64Field(value: self.lastKnownBlockCumulativeTxoCount, fieldNumber: 9)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: FogView_QueryResponse, rhs: FogView_QueryResponse) -> Bool {
    if lhs.highestProcessedBlockCount != rhs.highestProcessedBlockCount {return false}
    if lhs.highestProcessedBlockSignatureTimestamp != rhs.highestProcessedBlockSignatureTimestamp {return false}
    if lhs.nextStartFromUserEventID != rhs.nextStartFromUserEventID {return false}
    if lhs.missedBlockRanges != rhs.missedBlockRanges {return false}
    if lhs.rngs != rhs.rngs {return false}
    if lhs.decommissionedIngestInvocations != rhs.decommissionedIngestInvocations {return false}
    if lhs.txOutSearchResults != rhs.txOutSearchResults {return false}
    if lhs.lastKnownBlockCount != rhs.lastKnownBlockCount {return false}
    if lhs.lastKnownBlockCumulativeTxoCount != rhs.lastKnownBlockCumulativeTxoCount {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension FogView_RngRecord: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".RngRecord"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "ingest_invocation_id"),
    2: .same(proto: "pubkey"),
    3: .standard(proto: "start_block"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt64Field(value: &self.ingestInvocationID) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._pubkey) }()
      case 3: try { try decoder.decodeSingularUInt64Field(value: &self.startBlock) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.ingestInvocationID != 0 {
      try visitor.visitSingularInt64Field(value: self.ingestInvocationID, fieldNumber: 1)
    }
    if let v = self._pubkey {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }
    if self.startBlock != 0 {
      try visitor.visitSingularUInt64Field(value: self.startBlock, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: FogView_RngRecord, rhs: FogView_RngRecord) -> Bool {
    if lhs.ingestInvocationID != rhs.ingestInvocationID {return false}
    if lhs._pubkey != rhs._pubkey {return false}
    if lhs.startBlock != rhs.startBlock {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension FogView_DecommissionedIngestInvocation: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".DecommissionedIngestInvocation"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "ingest_invocation_id"),
    2: .standard(proto: "last_ingested_block"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularInt64Field(value: &self.ingestInvocationID) }()
      case 2: try { try decoder.decodeSingularUInt64Field(value: &self.lastIngestedBlock) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.ingestInvocationID != 0 {
      try visitor.visitSingularInt64Field(value: self.ingestInvocationID, fieldNumber: 1)
    }
    if self.lastIngestedBlock != 0 {
      try visitor.visitSingularUInt64Field(value: self.lastIngestedBlock, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: FogView_DecommissionedIngestInvocation, rhs: FogView_DecommissionedIngestInvocation) -> Bool {
    if lhs.ingestInvocationID != rhs.ingestInvocationID {return false}
    if lhs.lastIngestedBlock != rhs.lastIngestedBlock {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension FogView_TxOutSearchResult: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".TxOutSearchResult"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "search_key"),
    2: .standard(proto: "result_code"),
    3: .same(proto: "ciphertext"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.searchKey) }()
      case 2: try { try decoder.decodeSingularFixed32Field(value: &self.resultCode) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.ciphertext) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.searchKey.isEmpty {
      try visitor.visitSingularBytesField(value: self.searchKey, fieldNumber: 1)
    }
    if self.resultCode != 0 {
      try visitor.visitSingularFixed32Field(value: self.resultCode, fieldNumber: 2)
    }
    if !self.ciphertext.isEmpty {
      try visitor.visitSingularBytesField(value: self.ciphertext, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: FogView_TxOutSearchResult, rhs: FogView_TxOutSearchResult) -> Bool {
    if lhs.searchKey != rhs.searchKey {return false}
    if lhs.resultCode != rhs.resultCode {return false}
    if lhs.ciphertext != rhs.ciphertext {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension FogView_FogTxOut: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".FogTxOut"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "amount"),
    2: .standard(proto: "target_key"),
    3: .standard(proto: "public_key"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._amount) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._targetKey) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._publicKey) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._amount {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    }
    if let v = self._targetKey {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }
    if let v = self._publicKey {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: FogView_FogTxOut, rhs: FogView_FogTxOut) -> Bool {
    if lhs._amount != rhs._amount {return false}
    if lhs._targetKey != rhs._targetKey {return false}
    if lhs._publicKey != rhs._publicKey {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension FogView_TxOutRecord: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".TxOutRecord"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "tx_out_amount_commitment_data"),
    2: .standard(proto: "tx_out_amount_masked_value"),
    3: .standard(proto: "tx_out_target_key_data"),
    4: .standard(proto: "tx_out_public_key_data"),
    5: .standard(proto: "tx_out_global_index"),
    6: .standard(proto: "block_index"),
    7: .same(proto: "timestamp"),
  ]

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.txOutAmountCommitmentData) }()
      case 2: try { try decoder.decodeSingularFixed64Field(value: &self.txOutAmountMaskedValue) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.txOutTargetKeyData) }()
      case 4: try { try decoder.decodeSingularBytesField(value: &self.txOutPublicKeyData) }()
      case 5: try { try decoder.decodeSingularFixed64Field(value: &self.txOutGlobalIndex) }()
      case 6: try { try decoder.decodeSingularFixed64Field(value: &self.blockIndex) }()
      case 7: try { try decoder.decodeSingularFixed64Field(value: &self.timestamp) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.txOutAmountCommitmentData.isEmpty {
      try visitor.visitSingularBytesField(value: self.txOutAmountCommitmentData, fieldNumber: 1)
    }
    if self.txOutAmountMaskedValue != 0 {
      try visitor.visitSingularFixed64Field(value: self.txOutAmountMaskedValue, fieldNumber: 2)
    }
    if !self.txOutTargetKeyData.isEmpty {
      try visitor.visitSingularBytesField(value: self.txOutTargetKeyData, fieldNumber: 3)
    }
    if !self.txOutPublicKeyData.isEmpty {
      try visitor.visitSingularBytesField(value: self.txOutPublicKeyData, fieldNumber: 4)
    }
    if self.txOutGlobalIndex != 0 {
      try visitor.visitSingularFixed64Field(value: self.txOutGlobalIndex, fieldNumber: 5)
    }
    if self.blockIndex != 0 {
      try visitor.visitSingularFixed64Field(value: self.blockIndex, fieldNumber: 6)
    }
    if self.timestamp != 0 {
      try visitor.visitSingularFixed64Field(value: self.timestamp, fieldNumber: 7)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: FogView_TxOutRecord, rhs: FogView_TxOutRecord) -> Bool {
    if lhs.txOutAmountCommitmentData != rhs.txOutAmountCommitmentData {return false}
    if lhs.txOutAmountMaskedValue != rhs.txOutAmountMaskedValue {return false}
    if lhs.txOutTargetKeyData != rhs.txOutTargetKeyData {return false}
    if lhs.txOutPublicKeyData != rhs.txOutPublicKeyData {return false}
    if lhs.txOutGlobalIndex != rhs.txOutGlobalIndex {return false}
    if lhs.blockIndex != rhs.blockIndex {return false}
    if lhs.timestamp != rhs.timestamp {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
