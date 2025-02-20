//
//  WebDAVAuthenticationCoordinator.swift
//  Cryptomator
//
//  Created by Philipp Schmid on 07.04.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CryptomatorCloudAccessCore
import CryptomatorCommonCore
import Promises
import UIKit

class WebDAVAuthenticationCoordinator: NSObject, Coordinator, WebDAVAuthenticating, UIAdaptivePresentationControllerDelegate {
	var navigationController: UINavigationController
	var childCoordinators = [Coordinator]()
	weak var parentCoordinator: Coordinator?

	private(set) var pendingAuthentication: Promise<WebDAVCredential>

	init(navigationController: UINavigationController) {
		self.navigationController = navigationController
		self.pendingAuthentication = Promise<WebDAVCredential>.pending()
		super.init()
		navigationController.presentationController?.delegate = self
	}

	func start() {
		let viewModel = WebDAVAuthenticationViewModel()
		let webDAVAuthenticationVC = WebDAVAuthenticationViewController(viewModel: viewModel)
		webDAVAuthenticationVC.coordinator = self
		navigationController.pushViewController(webDAVAuthenticationVC, animated: false)
	}

	private func close() {
		navigationController.dismiss(animated: true)
		parentCoordinator?.childDidFinish(self)
	}

	// MARK: - WebDAVAuthenticating

	func authenticated(with credential: WebDAVCredential) {
		pendingAuthentication.fulfill(credential)
		close()
	}

	func handleUntrustedCertificate(_ certificate: TLSCertificate, url: URL, for viewController: WebDAVAuthenticationViewController, viewModel: WebDAVAuthenticationViewModelProtocol) {
		let alertController = UIAlertController(title: LocalizedString.getValue("untrustedTLSCertificate.title"), message: String(format: LocalizedString.getValue("untrustedTLSCertificate.message"), url.absoluteString, certificate.fingerprint), preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: LocalizedString.getValue("untrustedTLSCertificate.add"), style: .default, handler: { _ in
			viewController.addAccount(allowedCertificate: certificate.data, allowHTTPConnection: false)
		}))
		alertController.addAction(UIAlertAction(title: LocalizedString.getValue("untrustedTLSCertificate.dismiss"), style: .cancel))
		viewController.present(alertController, animated: true)
	}

	func handleInsecureConnection(for viewController: WebDAVAuthenticationViewController, viewModel: WebDAVAuthenticationViewModelProtocol) {
		let alertController = UIAlertController(title: LocalizedString.getValue("webDAVAuthentication.httpConnection.alert.title"),
		                                        message: LocalizedString.getValue("webDAVAuthentication.httpConnection.alert.message"),
		                                        preferredStyle: .alert)
		let changeToHTTPSAction = UIAlertAction(title: LocalizedString.getValue("webDAVAuthentication.httpConnection.change"), style: .default, handler: { _ in
			self.addAccountWithTransformedURL(for: viewController, viewModel: viewModel)
		})

		alertController.addAction(changeToHTTPSAction)
		alertController.preferredAction = changeToHTTPSAction
		alertController.addAction(UIAlertAction(title: LocalizedString.getValue("webDAVAuthentication.httpConnection.continue"), style: .destructive, handler: { _ in
			viewController.addAccount(allowedCertificate: nil, allowHTTPConnection: true)
		}))
		viewController.present(alertController, animated: true)
	}

	func cancel() {
		pendingAuthentication.reject(WebDAVAuthenticationError.userCanceled)
		close()
	}

	// MARK: - UIAdaptivePresentationControllerDelegate

	func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		// User has canceled the authentication by closing the modal via swipe
		pendingAuthentication.reject(WebDAVAuthenticationError.userCanceled)
	}

	private func addAccountWithTransformedURL(for viewController: WebDAVAuthenticationViewController, viewModel: WebDAVAuthenticationViewModelProtocol) {
		do {
			try viewModel.transformURLToHTTPS()
		} catch {
			handleError(error, for: viewController)
			return
		}
		viewController.addAccount(allowedCertificate: nil, allowHTTPConnection: false)
	}
}
