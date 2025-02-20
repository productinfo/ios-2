//
//  ItemMetadata.swift
//  CryptomatorFileProvider
//
//  Created by Philipp Schmid on 24.06.20.
//  Copyright © 2020 Skymatic GmbH. All rights reserved.
//

import CryptomatorCloudAccessCore
import Foundation
import GRDB

public class ItemMetadata: Record, Codable {
	override public class var databaseTableName: String {
		"itemMetadata"
	}

	override public static var databaseSelection: [SQLSelectable] {
		[AllColumns(), Column.rowID]
	}

	var id: Int64?
	var name: String
	let type: CloudItemType
	var size: Int?
	var parentID: Int64
	var lastModifiedDate: Date?
	var statusCode: ItemStatus
	var cloudPath: CloudPath
	var isPlaceholderItem: Bool
	var isMaybeOutdated: Bool

	required init(row: Row) {
		self.id = row[Columns.id]
		self.name = row[Columns.name]
		self.type = row[Columns.type]
		self.size = row[Columns.size]
		self.parentID = row[Columns.parentID]
		self.lastModifiedDate = row[Columns.lastModifiedDate]
		self.statusCode = row[Columns.statusCode]
		self.cloudPath = row[Columns.cloudPath]
		self.isPlaceholderItem = row[Columns.isPlaceholderItem]
		self.isMaybeOutdated = row[Columns.isMaybeOutdated]
		super.init(row: row)
	}

	init(id: Int64? = nil, name: String, type: CloudItemType, size: Int?, parentID: Int64, lastModifiedDate: Date?, statusCode: ItemStatus, cloudPath: CloudPath, isPlaceholderItem: Bool, isCandidateForCacheCleanup: Bool = false) {
		self.id = id
		self.name = name
		self.type = type
		self.size = size
		self.parentID = parentID
		self.lastModifiedDate = lastModifiedDate
		self.statusCode = statusCode
		self.cloudPath = cloudPath
		self.isPlaceholderItem = isPlaceholderItem
		self.isMaybeOutdated = isCandidateForCacheCleanup
		super.init()
	}

	override public func didInsert(with rowID: Int64, for column: String?) {
		id = rowID
	}

	override public func encode(to container: inout PersistenceContainer) {
		container[Columns.id] = id
		container[Columns.name] = name
		container[Columns.type] = type
		container[Columns.size] = size
		container[Columns.parentID] = parentID
		container[Columns.lastModifiedDate] = lastModifiedDate
		container[Columns.statusCode] = statusCode
		container[Columns.cloudPath] = cloudPath
		container[Columns.isPlaceholderItem] = isPlaceholderItem
		container[Columns.isMaybeOutdated] = isMaybeOutdated
	}

	enum Columns: String, ColumnExpression {
		case id, name, type, size, parentID, lastModifiedDate, statusCode, cloudPath, isPlaceholderItem, isMaybeOutdated
	}
}

extension ItemStatus: DatabaseValueConvertible {}
