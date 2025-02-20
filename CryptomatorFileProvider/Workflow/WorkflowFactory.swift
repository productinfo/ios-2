//
//  WorkflowFactory.swift
//  CryptomatorFileProvider
//
//  Created by Philipp Schmid on 28.05.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CryptomatorCloudAccessCore
import Foundation

enum WorkflowFactory {
	static func createWorkflow(for deletionTask: DeletionTask, provider: CloudProvider, itemMetadataManager: ItemMetadataManager) -> Workflow<Void> {
		let pathLockMiddleware = CreatingOrDeletingItemPathLockHandler<Void>()
		let taskExecutor = DeletionTaskExecutor(provider: provider, itemMetadataManager: itemMetadataManager)
		let errorMapper = ErrorMapper<Void>()

		errorMapper.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		pathLockMiddleware.setNext(errorMapper.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: deletionTask, constraint: .unconstrained)
	}

	static func createWorkflow(for uploadTask: UploadTask, provider: CloudProvider, itemMetadataManager: ItemMetadataManager, cachedFileManager: CachedFileManager, uploadTaskManager: UploadTaskManager) -> Workflow<FileProviderItem> {
		let pathLockMiddleware = CreatingOrDeletingItemPathLockHandler<FileProviderItem>()
		let onlineItemNameCollisionHandler = OnlineItemNameCollisionHandler<FileProviderItem>(itemMetadataManager: itemMetadataManager)
		let taskExecutor = UploadTaskExecutor(provider: provider, cachedFileManager: cachedFileManager, itemMetadataManager: itemMetadataManager, uploadTaskManager: uploadTaskManager)
		let errorMapper = ErrorMapper<FileProviderItem>()

		errorMapper.setNext(onlineItemNameCollisionHandler.eraseToAnyWorkflowMiddleware())
		onlineItemNameCollisionHandler.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		pathLockMiddleware.setNext(errorMapper.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: uploadTask, constraint: .uploadConstrained)
	}

	static func createWorkflow(for downloadTask: DownloadTask, provider: CloudProvider, itemMetadataManager: ItemMetadataManager, cachedFileManager: CachedFileManager, downloadTaskManager: DownloadTaskManager) -> Workflow<FileProviderItem> {
		let pathLockMiddleware = ReadingItemPathLockHandler<FileProviderItem>()
		let taskExecutor = DownloadTaskExecutor(provider: provider, itemMetadataManager: itemMetadataManager, cachedFileManager: cachedFileManager, downloadTaskManager: downloadTaskManager)
		let errorMapper = ErrorMapper<FileProviderItem>()

		errorMapper.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		pathLockMiddleware.setNext(errorMapper.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: downloadTask, constraint: .downloadConstrained)
	}

	static func createWorkflow(for reparenTask: ReparentTask, provider: CloudProvider, itemMetadataManager: ItemMetadataManager, cachedFileManager: CachedFileManager, reparentTaskManager: ReparentTaskManager) -> Workflow<FileProviderItem> {
		let pathLockMiddleware = MovingItemPathLockHandler()
		let onlineItemNameCollisionHandler = OnlineItemNameCollisionHandler<FileProviderItem>(itemMetadataManager: itemMetadataManager)
		let taskExecutor = ReparentTaskExecutor(provider: provider, reparentTaskManager: reparentTaskManager, itemMetadataManager: itemMetadataManager, cachedFileManager: cachedFileManager)
		let errorMapper = ErrorMapper<FileProviderItem>()

		errorMapper.setNext(onlineItemNameCollisionHandler.eraseToAnyWorkflowMiddleware())
		onlineItemNameCollisionHandler.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		pathLockMiddleware.setNext(errorMapper.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: reparenTask, constraint: .unconstrained)
	}

	// swiftlint:disable:next function_parameter_count
	static func createWorkflow(for itemEnumerationTask: ItemEnumerationTask, provider: CloudProvider, itemMetadataManager: ItemMetadataManager, cachedFileManager: CachedFileManager, reparentTaskManager: ReparentTaskManager, uploadTaskManager: UploadTaskManager, deletionTaskManager: DeletionTaskManager, itemEnumerationTaskManager: ItemEnumerationTaskManager) -> Workflow<FileProviderItemList> {
		let pathLockMiddleware = ReadingItemPathLockHandler<FileProviderItemList>()
		let deleteItemHelper = DeleteItemHelper(itemMetadataManager: itemMetadataManager, cachedFileManager: cachedFileManager)
		let taskExecutor = ItemEnumerationTaskExecutor(provider: provider, itemMetadataManager: itemMetadataManager, cachedFileManager: cachedFileManager, uploadTaskManager: uploadTaskManager, reparentTaskManager: reparentTaskManager, deletionTaskManager: deletionTaskManager, itemEnumerationTaskManager: itemEnumerationTaskManager, deleteItemHelper: deleteItemHelper)
		let errorMapper = ErrorMapper<FileProviderItemList>()

		errorMapper.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		pathLockMiddleware.setNext(errorMapper.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: itemEnumerationTask, constraint: .unconstrained)
	}

	static func createWorkflow(for folderCreationTask: FolderCreationTask, provider: CloudProvider, itemMetadataManager: ItemMetadataManager) -> Workflow<FileProviderItem> {
		let pathLockMiddleware = CreatingOrDeletingItemPathLockHandler<FileProviderItem>()
		let onlineItemNameCollisionHandler = OnlineItemNameCollisionHandler<FileProviderItem>(itemMetadataManager: itemMetadataManager)
		let taskExecutor = FolderCreationTaskExecutor(provider: provider, itemMetadataManager: itemMetadataManager)
		let errorMapper = ErrorMapper<FileProviderItem>()

		errorMapper.setNext(onlineItemNameCollisionHandler.eraseToAnyWorkflowMiddleware())
		onlineItemNameCollisionHandler.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		pathLockMiddleware.setNext(errorMapper.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: folderCreationTask, constraint: .unconstrained)
	}
}
