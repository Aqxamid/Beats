// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrapped_report.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWrappedReportCollection on Isar {
  IsarCollection<WrappedReport> get wrappedReports => this.collection();
}

const WrappedReportSchema = CollectionSchema(
  name: r'WrappedReport',
  id: -206112053547897934,
  properties: {
    r'cadence': PropertySchema(
      id: 0,
      name: r'cadence',
      type: IsarType.string,
    ),
    r'generatedAt': PropertySchema(
      id: 1,
      name: r'generatedAt',
      type: IsarType.dateTime,
    ),
    r'genreJsonStr': PropertySchema(
      id: 2,
      name: r'genreJsonStr',
      type: IsarType.string,
    ),
    r'llmRecap': PropertySchema(
      id: 3,
      name: r'llmRecap',
      type: IsarType.string,
    ),
    r'peakHourLabel': PropertySchema(
      id: 4,
      name: r'peakHourLabel',
      type: IsarType.string,
    ),
    r'periodLabel': PropertySchema(
      id: 5,
      name: r'periodLabel',
      type: IsarType.string,
    ),
    r'personalityEmoji': PropertySchema(
      id: 6,
      name: r'personalityEmoji',
      type: IsarType.string,
    ),
    r'personalityType': PropertySchema(
      id: 7,
      name: r'personalityType',
      type: IsarType.string,
    ),
    r'skipRate': PropertySchema(
      id: 8,
      name: r'skipRate',
      type: IsarType.double,
    ),
    r'slidesJsonStr': PropertySchema(
      id: 9,
      name: r'slidesJsonStr',
      type: IsarType.string,
    ),
    r'streakDays': PropertySchema(
      id: 10,
      name: r'streakDays',
      type: IsarType.long,
    ),
    r'topArtist': PropertySchema(
      id: 11,
      name: r'topArtist',
      type: IsarType.string,
    ),
    r'topArtistPlays': PropertySchema(
      id: 12,
      name: r'topArtistPlays',
      type: IsarType.long,
    ),
    r'topSong': PropertySchema(
      id: 13,
      name: r'topSong',
      type: IsarType.string,
    ),
    r'totalMinutes': PropertySchema(
      id: 14,
      name: r'totalMinutes',
      type: IsarType.long,
    ),
    r'totalSongs': PropertySchema(
      id: 15,
      name: r'totalSongs',
      type: IsarType.long,
    )
  },
  estimateSize: _wrappedReportEstimateSize,
  serialize: _wrappedReportSerialize,
  deserialize: _wrappedReportDeserialize,
  deserializeProp: _wrappedReportDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _wrappedReportGetId,
  getLinks: _wrappedReportGetLinks,
  attach: _wrappedReportAttach,
  version: '3.1.0+1',
);

int _wrappedReportEstimateSize(
  WrappedReport object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cadence.length * 3;
  bytesCount += 3 + object.genreJsonStr.length * 3;
  bytesCount += 3 + object.llmRecap.length * 3;
  bytesCount += 3 + object.peakHourLabel.length * 3;
  bytesCount += 3 + object.periodLabel.length * 3;
  bytesCount += 3 + object.personalityEmoji.length * 3;
  bytesCount += 3 + object.personalityType.length * 3;
  bytesCount += 3 + object.slidesJsonStr.length * 3;
  bytesCount += 3 + object.topArtist.length * 3;
  bytesCount += 3 + object.topSong.length * 3;
  return bytesCount;
}

void _wrappedReportSerialize(
  WrappedReport object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cadence);
  writer.writeDateTime(offsets[1], object.generatedAt);
  writer.writeString(offsets[2], object.genreJsonStr);
  writer.writeString(offsets[3], object.llmRecap);
  writer.writeString(offsets[4], object.peakHourLabel);
  writer.writeString(offsets[5], object.periodLabel);
  writer.writeString(offsets[6], object.personalityEmoji);
  writer.writeString(offsets[7], object.personalityType);
  writer.writeDouble(offsets[8], object.skipRate);
  writer.writeString(offsets[9], object.slidesJsonStr);
  writer.writeLong(offsets[10], object.streakDays);
  writer.writeString(offsets[11], object.topArtist);
  writer.writeLong(offsets[12], object.topArtistPlays);
  writer.writeString(offsets[13], object.topSong);
  writer.writeLong(offsets[14], object.totalMinutes);
  writer.writeLong(offsets[15], object.totalSongs);
}

WrappedReport _wrappedReportDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WrappedReport();
  object.cadence = reader.readString(offsets[0]);
  object.generatedAt = reader.readDateTime(offsets[1]);
  object.genreJsonStr = reader.readString(offsets[2]);
  object.id = id;
  object.llmRecap = reader.readString(offsets[3]);
  object.peakHourLabel = reader.readString(offsets[4]);
  object.periodLabel = reader.readString(offsets[5]);
  object.personalityEmoji = reader.readString(offsets[6]);
  object.personalityType = reader.readString(offsets[7]);
  object.skipRate = reader.readDouble(offsets[8]);
  object.slidesJsonStr = reader.readString(offsets[9]);
  object.streakDays = reader.readLong(offsets[10]);
  object.topArtist = reader.readString(offsets[11]);
  object.topArtistPlays = reader.readLong(offsets[12]);
  object.topSong = reader.readString(offsets[13]);
  object.totalMinutes = reader.readLong(offsets[14]);
  object.totalSongs = reader.readLong(offsets[15]);
  return object;
}

P _wrappedReportDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _wrappedReportGetId(WrappedReport object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _wrappedReportGetLinks(WrappedReport object) {
  return [];
}

void _wrappedReportAttach(
    IsarCollection<dynamic> col, Id id, WrappedReport object) {
  object.id = id;
}

extension WrappedReportQueryWhereSort
    on QueryBuilder<WrappedReport, WrappedReport, QWhere> {
  QueryBuilder<WrappedReport, WrappedReport, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension WrappedReportQueryWhere
    on QueryBuilder<WrappedReport, WrappedReport, QWhereClause> {
  QueryBuilder<WrappedReport, WrappedReport, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WrappedReportQueryFilter
    on QueryBuilder<WrappedReport, WrappedReport, QFilterCondition> {
  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      cadenceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      cadenceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      cadenceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      cadenceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cadence',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      cadenceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      cadenceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      cadenceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cadence',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      cadenceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cadence',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      cadenceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cadence',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      cadenceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cadence',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      generatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'generatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      generatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'generatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      generatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'generatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      generatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'generatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      genreJsonStrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'genreJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      genreJsonStrGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'genreJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      genreJsonStrLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'genreJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      genreJsonStrBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'genreJsonStr',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      genreJsonStrStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'genreJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      genreJsonStrEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'genreJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      genreJsonStrContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'genreJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      genreJsonStrMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'genreJsonStr',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      genreJsonStrIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'genreJsonStr',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      genreJsonStrIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'genreJsonStr',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      llmRecapEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'llmRecap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      llmRecapGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'llmRecap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      llmRecapLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'llmRecap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      llmRecapBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'llmRecap',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      llmRecapStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'llmRecap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      llmRecapEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'llmRecap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      llmRecapContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'llmRecap',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      llmRecapMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'llmRecap',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      llmRecapIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'llmRecap',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      llmRecapIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'llmRecap',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      peakHourLabelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'peakHourLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      peakHourLabelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'peakHourLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      peakHourLabelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'peakHourLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      peakHourLabelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'peakHourLabel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      peakHourLabelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'peakHourLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      peakHourLabelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'peakHourLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      peakHourLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'peakHourLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      peakHourLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'peakHourLabel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      peakHourLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'peakHourLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      peakHourLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'peakHourLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      periodLabelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      periodLabelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      periodLabelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      periodLabelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodLabel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      periodLabelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'periodLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      periodLabelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'periodLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      periodLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'periodLabel',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      periodLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'periodLabel',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      periodLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      periodLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'periodLabel',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityEmojiEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personalityEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityEmojiGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'personalityEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityEmojiLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'personalityEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityEmojiBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'personalityEmoji',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityEmojiStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'personalityEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityEmojiEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'personalityEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityEmojiContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'personalityEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityEmojiMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'personalityEmoji',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityEmojiIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personalityEmoji',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityEmojiIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'personalityEmoji',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personalityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'personalityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'personalityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'personalityType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'personalityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'personalityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'personalityType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'personalityType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'personalityType',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      personalityTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'personalityType',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      skipRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'skipRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      skipRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'skipRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      skipRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'skipRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      skipRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'skipRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      slidesJsonStrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slidesJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      slidesJsonStrGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'slidesJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      slidesJsonStrLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'slidesJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      slidesJsonStrBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'slidesJsonStr',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      slidesJsonStrStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'slidesJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      slidesJsonStrEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'slidesJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      slidesJsonStrContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'slidesJsonStr',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      slidesJsonStrMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'slidesJsonStr',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      slidesJsonStrIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slidesJsonStr',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      slidesJsonStrIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'slidesJsonStr',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      streakDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'streakDays',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      streakDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'streakDays',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      streakDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'streakDays',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      streakDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'streakDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topArtist',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'topArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'topArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'topArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'topArtist',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topArtist',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'topArtist',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistPlaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topArtistPlays',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistPlaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topArtistPlays',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistPlaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topArtistPlays',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topArtistPlaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topArtistPlays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topSongEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topSong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topSongGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'topSong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topSongLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'topSong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topSongBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'topSong',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topSongStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'topSong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topSongEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'topSong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topSongContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'topSong',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topSongMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'topSong',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topSongIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'topSong',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      topSongIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'topSong',
        value: '',
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      totalMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      totalMinutesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      totalMinutesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      totalMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      totalSongsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalSongs',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      totalSongsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalSongs',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      totalSongsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalSongs',
        value: value,
      ));
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterFilterCondition>
      totalSongsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalSongs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension WrappedReportQueryObject
    on QueryBuilder<WrappedReport, WrappedReport, QFilterCondition> {}

extension WrappedReportQueryLinks
    on QueryBuilder<WrappedReport, WrappedReport, QFilterCondition> {}

extension WrappedReportQuerySortBy
    on QueryBuilder<WrappedReport, WrappedReport, QSortBy> {
  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> sortByCadence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cadence', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> sortByCadenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cadence', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> sortByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByGeneratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByGenreJsonStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'genreJsonStr', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByGenreJsonStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'genreJsonStr', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> sortByLlmRecap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'llmRecap', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByLlmRecapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'llmRecap', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByPeakHourLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peakHourLabel', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByPeakHourLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peakHourLabel', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> sortByPeriodLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodLabel', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByPeriodLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodLabel', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByPersonalityEmoji() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personalityEmoji', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByPersonalityEmojiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personalityEmoji', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByPersonalityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personalityType', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByPersonalityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personalityType', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> sortBySkipRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipRate', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortBySkipRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipRate', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortBySlidesJsonStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slidesJsonStr', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortBySlidesJsonStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slidesJsonStr', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> sortByStreakDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakDays', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByStreakDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakDays', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> sortByTopArtist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topArtist', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByTopArtistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topArtist', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByTopArtistPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topArtistPlays', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByTopArtistPlaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topArtistPlays', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> sortByTopSong() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topSong', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> sortByTopSongDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topSong', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByTotalMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMinutes', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByTotalMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMinutes', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> sortByTotalSongs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSongs', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      sortByTotalSongsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSongs', Sort.desc);
    });
  }
}

extension WrappedReportQuerySortThenBy
    on QueryBuilder<WrappedReport, WrappedReport, QSortThenBy> {
  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenByCadence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cadence', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenByCadenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cadence', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByGeneratedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'generatedAt', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByGenreJsonStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'genreJsonStr', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByGenreJsonStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'genreJsonStr', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenByLlmRecap() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'llmRecap', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByLlmRecapDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'llmRecap', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByPeakHourLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peakHourLabel', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByPeakHourLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'peakHourLabel', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenByPeriodLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodLabel', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByPeriodLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodLabel', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByPersonalityEmoji() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personalityEmoji', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByPersonalityEmojiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personalityEmoji', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByPersonalityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personalityType', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByPersonalityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'personalityType', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenBySkipRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipRate', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenBySkipRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'skipRate', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenBySlidesJsonStr() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slidesJsonStr', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenBySlidesJsonStrDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slidesJsonStr', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenByStreakDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakDays', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByStreakDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'streakDays', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenByTopArtist() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topArtist', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByTopArtistDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topArtist', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByTopArtistPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topArtistPlays', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByTopArtistPlaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topArtistPlays', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenByTopSong() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topSong', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenByTopSongDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'topSong', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByTotalMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMinutes', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByTotalMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalMinutes', Sort.desc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy> thenByTotalSongs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSongs', Sort.asc);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QAfterSortBy>
      thenByTotalSongsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalSongs', Sort.desc);
    });
  }
}

extension WrappedReportQueryWhereDistinct
    on QueryBuilder<WrappedReport, WrappedReport, QDistinct> {
  QueryBuilder<WrappedReport, WrappedReport, QDistinct> distinctByCadence(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cadence', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct>
      distinctByGeneratedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'generatedAt');
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct> distinctByGenreJsonStr(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'genreJsonStr', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct> distinctByLlmRecap(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'llmRecap', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct> distinctByPeakHourLabel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'peakHourLabel',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct> distinctByPeriodLabel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodLabel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct>
      distinctByPersonalityEmoji({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personalityEmoji',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct>
      distinctByPersonalityType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'personalityType',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct> distinctBySkipRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'skipRate');
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct> distinctBySlidesJsonStr(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'slidesJsonStr',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct> distinctByStreakDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'streakDays');
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct> distinctByTopArtist(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topArtist', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct>
      distinctByTopArtistPlays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topArtistPlays');
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct> distinctByTopSong(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'topSong', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct>
      distinctByTotalMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalMinutes');
    });
  }

  QueryBuilder<WrappedReport, WrappedReport, QDistinct> distinctByTotalSongs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalSongs');
    });
  }
}

extension WrappedReportQueryProperty
    on QueryBuilder<WrappedReport, WrappedReport, QQueryProperty> {
  QueryBuilder<WrappedReport, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WrappedReport, String, QQueryOperations> cadenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cadence');
    });
  }

  QueryBuilder<WrappedReport, DateTime, QQueryOperations>
      generatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'generatedAt');
    });
  }

  QueryBuilder<WrappedReport, String, QQueryOperations> genreJsonStrProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'genreJsonStr');
    });
  }

  QueryBuilder<WrappedReport, String, QQueryOperations> llmRecapProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'llmRecap');
    });
  }

  QueryBuilder<WrappedReport, String, QQueryOperations>
      peakHourLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'peakHourLabel');
    });
  }

  QueryBuilder<WrappedReport, String, QQueryOperations> periodLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodLabel');
    });
  }

  QueryBuilder<WrappedReport, String, QQueryOperations>
      personalityEmojiProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personalityEmoji');
    });
  }

  QueryBuilder<WrappedReport, String, QQueryOperations>
      personalityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'personalityType');
    });
  }

  QueryBuilder<WrappedReport, double, QQueryOperations> skipRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'skipRate');
    });
  }

  QueryBuilder<WrappedReport, String, QQueryOperations>
      slidesJsonStrProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'slidesJsonStr');
    });
  }

  QueryBuilder<WrappedReport, int, QQueryOperations> streakDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'streakDays');
    });
  }

  QueryBuilder<WrappedReport, String, QQueryOperations> topArtistProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topArtist');
    });
  }

  QueryBuilder<WrappedReport, int, QQueryOperations> topArtistPlaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topArtistPlays');
    });
  }

  QueryBuilder<WrappedReport, String, QQueryOperations> topSongProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'topSong');
    });
  }

  QueryBuilder<WrappedReport, int, QQueryOperations> totalMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalMinutes');
    });
  }

  QueryBuilder<WrappedReport, int, QQueryOperations> totalSongsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalSongs');
    });
  }
}
