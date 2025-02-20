//
//  FileProviderAdapterMoveItemTests.swift
//  CryptomatorFileProviderTests
//
//  Created by Philipp Schmid on 07.06.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CryptomatorCloudAccessCore
import Foundation
import Promises
import XCTest
@testable import CryptomatorFileProvider

class FileProviderAdapterMoveItemTests: FileProviderAdapterTestCase {
	func testMoveItemLocally() throws {
		let rootItemMetadata = ItemMetadata(id: metadataManagerMock.getRootContainerID(), name: "Home", type: .folder, size: nil, parentID: metadataManagerMock.getRootContainerID(), lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: CloudPath("/"), isPlaceholderItem: false)
		try metadataManagerMock.cacheMetadata(rootItemMetadata)

		let parentItemID: Int64 = 2
		let itemID: Int64 = 3

		let sourceCloudPath = CloudPath("/Test.txt")
		let targetCloudPath = CloudPath("/Folder/RenamedTest.txt")
		let itemMetadata = ItemMetadata(id: itemID, name: "Test.txt", type: .file, size: nil, parentID: ItemMetadataDBManager.rootContainerId, lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: sourceCloudPath, isPlaceholderItem: false)
		let targetParentCloudPath = CloudPath("/Folder/")
		let newParentItemMetadata = ItemMetadata(id: parentItemID, name: "Folder", type: .folder, size: nil, parentID: ItemMetadataDBManager.rootContainerId, lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: targetParentCloudPath, isPlaceholderItem: false)
		try metadataManagerMock.cacheMetadata([itemMetadata, newParentItemMetadata])

		let itemIdentifier = NSFileProviderItemIdentifier(rawValue: String(itemID))
		let parentItemIdentifier = NSFileProviderItemIdentifier(rawValue: String(parentItemID))
		let newName = "RenamedTest.txt"
		let result = try adapter.moveItemLocally(withIdentifier: itemIdentifier, toParentItemWithIdentifier: parentItemIdentifier, newName: newName)
		let item = result.item
		XCTAssertEqual(newName, item.filename)
		XCTAssertEqual(parentItemIdentifier, item.parentItemIdentifier)
		XCTAssertEqual(itemIdentifier, item.itemIdentifier)
		XCTAssertEqual(ItemStatus.isUploading, item.metadata.statusCode)
		XCTAssertEqual(targetCloudPath, item.metadata.cloudPath)

		XCTAssertEqual(3, metadataManagerMock.cachedMetadata.count)
		XCTAssertEqual(itemMetadata, metadataManagerMock.cachedMetadata[itemID])

		XCTAssertEqual(newName, itemMetadata.name)
		XCTAssertEqual(newParentItemMetadata.id, itemMetadata.parentID)
		XCTAssertEqual(ItemStatus.isUploading, itemMetadata.statusCode)
		XCTAssertEqual(targetCloudPath, itemMetadata.cloudPath)

		let reparentTaskRecord = result.reparentTaskRecord
		XCTAssertEqual(itemID, reparentTaskRecord.correspondingItem)
		XCTAssertEqual(metadataManagerMock.getRootContainerID(), reparentTaskRecord.oldParentID)
		XCTAssertEqual(parentItemID, reparentTaskRecord.newParentID)
		XCTAssertEqual(sourceCloudPath, reparentTaskRecord.sourceCloudPath)
		XCTAssertEqual(targetCloudPath, reparentTaskRecord.targetCloudPath)
	}

	func testMoveItemLocallyOnlyNameChanged() throws {
		let rootItemMetadata = ItemMetadata(id: metadataManagerMock.getRootContainerID(), name: "Home", type: .folder, size: nil, parentID: metadataManagerMock.getRootContainerID(), lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: CloudPath("/"), isPlaceholderItem: false)
		try metadataManagerMock.cacheMetadata(rootItemMetadata)

		let sourceCloudPath = CloudPath("/Test.txt")
		let targetCloudPath = CloudPath("/RenamedTest.txt")
		let itemID: Int64 = 2
		let itemMetadata = ItemMetadata(id: itemID, name: "Test.txt", type: .file, size: nil, parentID: ItemMetadataDBManager.rootContainerId, lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: sourceCloudPath, isPlaceholderItem: false)
		metadataManagerMock.cachedMetadata[itemID] = itemMetadata
		let itemIdentifier = NSFileProviderItemIdentifier(rawValue: String(itemMetadata.id!))
		let newName = "RenamedTest.txt"
		let result = try adapter.moveItemLocally(withIdentifier: itemIdentifier, toParentItemWithIdentifier: nil, newName: newName)
		let item = result.item
		XCTAssertEqual(newName, item.filename)
		XCTAssertEqual(NSFileProviderItemIdentifier.rootContainer, item.parentItemIdentifier)
		XCTAssertEqual(itemIdentifier, item.itemIdentifier)
		XCTAssertEqual(ItemStatus.isUploading, item.metadata.statusCode)
		XCTAssertEqual(targetCloudPath, item.metadata.cloudPath)

		XCTAssertEqual(2, metadataManagerMock.cachedMetadata.count)
		XCTAssertEqual(itemMetadata, metadataManagerMock.cachedMetadata[itemID])

		XCTAssertEqual(newName, itemMetadata.name)
		XCTAssertEqual(ItemMetadataDBManager.rootContainerId, itemMetadata.parentID)
		XCTAssertEqual(ItemStatus.isUploading, itemMetadata.statusCode)
		XCTAssertEqual(targetCloudPath, itemMetadata.cloudPath)

		let reparentTaskRecord = result.reparentTaskRecord
		XCTAssertEqual(itemID, reparentTaskRecord.correspondingItem)
		XCTAssertEqual(sourceCloudPath, reparentTaskRecord.sourceCloudPath)
		XCTAssertEqual(targetCloudPath, reparentTaskRecord.targetCloudPath)
	}

	func testMoveItemLocallyOnlyParentChanged() throws {
		let rootItemMetadata = ItemMetadata(id: metadataManagerMock.getRootContainerID(), name: "Home", type: .folder, size: nil, parentID: metadataManagerMock.getRootContainerID(), lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: CloudPath("/"), isPlaceholderItem: false)
		try metadataManagerMock.cacheMetadata(rootItemMetadata)

		let parentItemID: Int64 = 2
		let itemID: Int64 = 3

		let sourceCloudPath = CloudPath("/Test.txt")
		let targetCloudPath = CloudPath("/Folder/Test.txt")
		let itemMetadata = ItemMetadata(id: itemID, name: "Test.txt", type: .file, size: nil, parentID: ItemMetadataDBManager.rootContainerId, lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: sourceCloudPath, isPlaceholderItem: false)
		let targetParentCloudPath = CloudPath("/Folder/")
		let newParentItemMetadata = ItemMetadata(id: parentItemID, name: "Folder", type: .folder, size: nil, parentID: ItemMetadataDBManager.rootContainerId, lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: targetParentCloudPath, isPlaceholderItem: false)
		try metadataManagerMock.cacheMetadata([itemMetadata, newParentItemMetadata])

		let itemIdentifier = NSFileProviderItemIdentifier(rawValue: String(itemMetadata.id!))
		let parentItemIdentifier = NSFileProviderItemIdentifier(rawValue: String(newParentItemMetadata.id!))
		let result = try adapter.moveItemLocally(withIdentifier: itemIdentifier, toParentItemWithIdentifier: parentItemIdentifier, newName: nil)
		let item = result.item
		XCTAssertEqual("Test.txt", item.filename)
		XCTAssertEqual(parentItemIdentifier, item.parentItemIdentifier)
		XCTAssertEqual(itemIdentifier, item.itemIdentifier)
		XCTAssertEqual(ItemStatus.isUploading, item.metadata.statusCode)
		XCTAssertEqual(targetCloudPath, item.metadata.cloudPath)

		XCTAssertEqual(3, metadataManagerMock.cachedMetadata.count)
		XCTAssertEqual(itemMetadata, metadataManagerMock.cachedMetadata[itemID])

		XCTAssertEqual("Test.txt", itemMetadata.name)
		XCTAssertEqual(parentItemID, itemMetadata.parentID)
		XCTAssertEqual(ItemStatus.isUploading, itemMetadata.statusCode)
		XCTAssertEqual(targetCloudPath, itemMetadata.cloudPath)
		let reparentTaskRecord = result.reparentTaskRecord

		XCTAssertEqual(itemID, reparentTaskRecord.correspondingItem)
		XCTAssertEqual(metadataManagerMock.getRootContainerID(), reparentTaskRecord.oldParentID)
		XCTAssertEqual(parentItemID, reparentTaskRecord.newParentID)
		XCTAssertEqual(sourceCloudPath, reparentTaskRecord.sourceCloudPath)
		XCTAssertEqual(targetCloudPath, reparentTaskRecord.targetCloudPath)
	}

	func testRenameItem() throws {
		let expectation = XCTestExpectation()

		let rootItemMetadata = ItemMetadata(id: metadataManagerMock.getRootContainerID(), name: "Home", type: .folder, size: nil, parentID: metadataManagerMock.getRootContainerID(), lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: CloudPath("/"), isPlaceholderItem: false)
		try metadataManagerMock.cacheMetadata(rootItemMetadata)

		let sourceCloudPath = CloudPath("/Test.txt")
		let targetCloudPath = CloudPath("/RenamedTest.txt")
		let itemID: Int64 = 2
		let itemMetadata = ItemMetadata(id: itemID, name: "Test.txt", type: .file, size: nil, parentID: ItemMetadataDBManager.rootContainerId, lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: sourceCloudPath, isPlaceholderItem: false)
		metadataManagerMock.cachedMetadata[itemID] = itemMetadata
		let newName = "RenamedTest.txt"
		let itemIdentifier = NSFileProviderItemIdentifier(rawValue: String(itemID))
		adapter.renameItem(withIdentifier: itemIdentifier, toName: newName) { item, error in
			XCTAssertNil(error)
			guard let fileProviderItem = item as? FileProviderItem else {
				XCTFail("FileProviderItem is nil")
				return
			}

			XCTAssertEqual(newName, fileProviderItem.filename)
			XCTAssertEqual(NSFileProviderItemIdentifier.rootContainer, fileProviderItem.parentItemIdentifier)
			XCTAssertEqual(itemIdentifier, fileProviderItem.itemIdentifier)
			XCTAssertEqual(ItemStatus.isUploading, fileProviderItem.metadata.statusCode)
			XCTAssertEqual(targetCloudPath, fileProviderItem.metadata.cloudPath)

			XCTAssertEqual(2, self.metadataManagerMock.cachedMetadata.count)
			XCTAssertEqual(itemMetadata, self.metadataManagerMock.cachedMetadata[itemID])

			XCTAssertEqual(newName, itemMetadata.name)
			XCTAssertEqual(ItemMetadataDBManager.rootContainerId, itemMetadata.parentID)
			XCTAssertEqual(ItemStatus.isUploading, itemMetadata.statusCode)
			XCTAssertEqual(targetCloudPath, itemMetadata.cloudPath)

			guard let reparentTaskRecord = self.reparentTaskManagerMock.reparentTasks[itemID] else {
				XCTFail("reparentTaskRecord is nil")
				return
			}
			XCTAssertEqual(itemID, reparentTaskRecord.correspondingItem)
			XCTAssertEqual(sourceCloudPath, reparentTaskRecord.sourceCloudPath)
			XCTAssertEqual(targetCloudPath, reparentTaskRecord.targetCloudPath)
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}

	func testReparentItem() throws {
		let expectation = XCTestExpectation()

		let rootItemMetadata = ItemMetadata(id: metadataManagerMock.getRootContainerID(), name: "Home", type: .folder, size: nil, parentID: metadataManagerMock.getRootContainerID(), lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: CloudPath("/"), isPlaceholderItem: false)
		try metadataManagerMock.cacheMetadata(rootItemMetadata)

		let parentItemID: Int64 = 2
		let itemID: Int64 = 3

		let sourceCloudPath = CloudPath("/Test.txt")
		let targetCloudPath = CloudPath("/Folder/Test.txt")
		let itemMetadata = ItemMetadata(id: itemID, name: "Test.txt", type: .file, size: nil, parentID: ItemMetadataDBManager.rootContainerId, lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: sourceCloudPath, isPlaceholderItem: false)
		let targetParentCloudPath = CloudPath("/Folder/")
		let newParentItemMetadata = ItemMetadata(id: parentItemID, name: "Folder", type: .folder, size: nil, parentID: ItemMetadataDBManager.rootContainerId, lastModifiedDate: nil, statusCode: .isUploaded, cloudPath: targetParentCloudPath, isPlaceholderItem: false)
		try metadataManagerMock.cacheMetadata([itemMetadata, newParentItemMetadata])

		let itemIdentifier = NSFileProviderItemIdentifier(rawValue: String(itemID))
		let parentItemIdentifier = NSFileProviderItemIdentifier(rawValue: String(parentItemID))
		adapter.reparentItem(withIdentifier: itemIdentifier, toParentItemWithIdentifier: parentItemIdentifier, newName: nil) { item, error in
			XCTAssertNil(error)
			guard let fileProviderItem = item as? FileProviderItem else {
				XCTFail("FileProviderItem is nil")
				return
			}
			XCTAssertEqual("Test.txt", fileProviderItem.filename)
			XCTAssertEqual(parentItemIdentifier, fileProviderItem.parentItemIdentifier)
			XCTAssertEqual(itemIdentifier, fileProviderItem.itemIdentifier)
			XCTAssertEqual(ItemStatus.isUploading, fileProviderItem.metadata.statusCode)
			XCTAssertEqual(targetCloudPath, fileProviderItem.metadata.cloudPath)

			XCTAssertEqual(3, self.metadataManagerMock.cachedMetadata.count)
			XCTAssertEqual(itemMetadata, self.metadataManagerMock.cachedMetadata[itemID])

			XCTAssertEqual("Test.txt", itemMetadata.name)
			XCTAssertEqual(parentItemID, itemMetadata.parentID)
			XCTAssertEqual(ItemStatus.isUploading, itemMetadata.statusCode)
			XCTAssertEqual(targetCloudPath, itemMetadata.cloudPath)

			guard let reparentTaskRecord = self.reparentTaskManagerMock.reparentTasks[itemID] else {
				XCTFail("reparentTaskRecord is nil")
				return
			}
			XCTAssertEqual(itemID, reparentTaskRecord.correspondingItem)
			XCTAssertEqual(self.metadataManagerMock.getRootContainerID(), reparentTaskRecord.oldParentID)
			XCTAssertEqual(parentItemID, reparentTaskRecord.newParentID)
			XCTAssertEqual(sourceCloudPath, reparentTaskRecord.sourceCloudPath)
			XCTAssertEqual(targetCloudPath, reparentTaskRecord.targetCloudPath)
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}
}
