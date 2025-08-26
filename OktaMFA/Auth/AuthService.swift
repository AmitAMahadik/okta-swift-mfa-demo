//
//  AuthService.swift
//  Okta MFA
//
//  Created by Mahadik, Amit on 8/25/25.
//

import Foundation
import BrowserSignin

protocol AuthServiceProtocol {
    var isAuthenticated: Bool { get }
    var idToken: String? { get }
    
    func tokenInfo() -> TokenInfo?
    func userInfo() async throws -> UserInfo?
    func signIn() async throws
    func signOut() async throws
    func refreshTokenIfNeeded() async throws
}

final class AuthService: AuthServiceProtocol {
    
    var isAuthenticated: Bool {
        return Credential.default != nil //Checking if a valid token exists before returning it
    }
    
    var idToken: String? {
        return Credential.default?.token.idToken?.rawValue // returns a signed JWT containing user identity info
    }
    
    @MainActor
    func signIn() async throws {
        BrowserSignin.shared?.ephemeralSession = true // Forces an ephemeral session - Incognito mode
        let tokens = try await BrowserSignin.shared?.signIn()
        if let tokens {
            print("Signed in with tokens: \(tokens)")
            _ = try? Credential.store(tokens) // Securely store credential in Okta's Credential storage helper
        }
    }
    
    @MainActor
    func signOut() async throws {
        guard let credential = Credential.default else { return }
        try await BrowserSignin.shared?.signOut(token: credential.token)
        try? credential.remove() // Remove credential from secure storage
    }
    
    func refreshTokenIfNeeded() async throws { // Keep tokens refreshed
        guard let credential = Credential.default else { return }
        try await credential.refresh()
    }
    
    func tokenInfo() -> TokenInfo? {
        guard let idToken = Credential.default?.token.idToken else {
            return nil
        }
        
        return TokenInfo(idToken: idToken)
    }
    
    func userInfo() async throws -> UserInfo? {
        if let userInfo = Credential.default?.userInfo {
            return userInfo
        } else {
            do {
                guard let userInfo = try await Credential.default?.userInfo() else {
                    return nil
                }
                return userInfo
            } catch {
                return nil
            }
        }
    }
}

