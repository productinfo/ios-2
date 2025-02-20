//
//  VaultListViewController.swift
//  Cryptomator
//
//  Created by Philipp Schmid on 04.01.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CocoaLumberjackSwift
import Combine
import CryptomatorCommonCore
import Foundation
import UIKit

class VaultListViewController: ListViewController<VaultCellViewModel> {
	weak var coordinator: MainCoordinator?

	private let viewModel: VaultListViewModelProtocol
	private var observer: NSObjectProtocol?

	init(with viewModel: VaultListViewModelProtocol) {
		self.viewModel = viewModel
		super.init(viewModel: viewModel)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Cryptomator"
		let settingsSymbol: UIImage?
		if #available(iOS 14, *) {
			settingsSymbol = UIImage(systemName: "gearshape")
		} else {
			settingsSymbol = UIImage(systemName: "gear")
		}
		let settingsButton = UIBarButtonItem(image: settingsSymbol, style: .plain, target: self, action: #selector(showSettings))
		navigationItem.leftBarButtonItem = settingsButton
		let addNewVaulButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewVault))
		navigationItem.rightBarButtonItem = addNewVaulButton

		observer = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
			self?.viewModel.refreshVaultLockStates().catch { error in
				DDLogError("Refresh vault lock states failed with error: \(error)")
			}
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		viewModel.refreshVaultLockStates().catch { error in
			DDLogError("Refresh vault lock states failed with error: \(error)")
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if CryptomatorUserDefaults.shared.showOnboardingAtStartup {
			coordinator?.showOnboarding()
		} else if UserDefaultsFullVersionChecker.shared.hasExpiredTrial, !CryptomatorUserDefaults.shared.showedTrialExpiredAtStartup {
			coordinator?.showTrialExpired()
		}
	}

	override func registerCells() {
		tableView.register(VaultCell.self, forCellReuseIdentifier: "VaultCell")
	}

	override func configureDataSource() {
		dataSource = EditableDataSource<Section, VaultCellViewModel>(tableView: tableView, cellProvider: { tableView, _, cellViewModel in
			let cell = tableView.dequeueReusableCell(withIdentifier: "VaultCell") as? VaultCell
			cell?.configure(with: cellViewModel)
			return cell
		})
	}

	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		header.isEditing = editing
	}

	@objc func addNewVault() {
		setEditing(false, animated: true)
		coordinator?.addVault()
	}

	@objc func showSettings() {
		setEditing(false, animated: true)
		coordinator?.showSettings()
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		if let vaultCellViewModel = dataSource?.itemIdentifier(for: indexPath) {
			coordinator?.showVaultDetail(for: vaultCellViewModel.vault)
		}
	}
}
