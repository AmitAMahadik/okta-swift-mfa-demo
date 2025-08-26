//
//  AuthView.swift
//  Okta MFA
//
//  Created by Mahadik, Amit on 8/25/25.
//

import SwiftUI
import BrowserSignin

/// The main authentication screen that shows the current login state,
/// allows the user to sign in or out, and access token/user info and server message.
struct AuthView: View {
    // View model manages all auth logic and state
    @State private var viewModel = AuthViewModel()

    // Presentation control flags for full-screen modals
    @State private var showTokenInfo = false
    
    // Holds the fetched user info data when available
    // And presents the UserInfoView when assigned value
    @State private var userInfo: UserInfoModel?

    var body: some View {
        VStack(spacing: 20) {
            statusSection
            tokenSection
            authButton
            if viewModel.isAuthenticated {
                refreshTokenButton
                tokenInfoButton // tokenInfoButton added here
                userInfoButton // userInfoButton added here
            }
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .padding()
        .onAppear {
            // Sync UI state on view load
            viewModel.updateUI()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            // Show error message if available
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
        // Show Token Info full screen
        .fullScreenCover(isPresented: $showTokenInfo) {
          if let tokenInfo = viewModel.fetchTokenInfo() {
            TokenInfoView(tokenInfo: tokenInfo)
          }
        }
        // Show User Info full screen
        .fullScreenCover(item: $userInfo) { info in
          UserInfoView(userInfo: info.user)
        }
    }
}

private extension AuthView {
    /// Displays "Logged In" or "Logged Out" depending on current state.
    var statusSection: some View {
        Text(viewModel.isAuthenticated ? "✅ Logged In" : "🔒 Logged Out")
            .font(.system(size: 24, weight: .medium))
            .multilineTextAlignment(.center)
    }

    /// Shows the user's ID token in small text (only when authenticated).
    var tokenSection: some View {
        Group {
            if let token = viewModel.idToken, viewModel.isAuthenticated {
                Text("ID Token:\n\(token)")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
            }
        }
    }

    /// Main login/logout button. Text and action change based on login state.
    var authButton: some View {
        Button(viewModel.isAuthenticated ? "Sign Out" : "Sign In") {
            Task { await viewModel.handleAuthAction() }
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isLoading)
    }

    /// Opens the full-screen view showing token info.
    var refreshTokenButton: some View {
        Button("🔄 Refresh Token") {
            Task { await viewModel.refreshToken() }
        }
        .font(.system(size: 14))
        .disabled(viewModel.isLoading)
    }
    
    /// Opens the full-screen view showing token info.
    var tokenInfoButton: some View {
      Button {
        showTokenInfo = true
      } label: {
          Image(systemName: "info.circle")
            .foregroundColor(.blue)
        }
        .disabled(viewModel.isLoading)
      }

      /// Loads user info and presents it full screen.
    var userInfoButton: some View {
        Button("👤 User Info") {
            Task {
                if let user = await viewModel.fetchUserInfo() {
                    await MainActor.run {
                        userInfo = UserInfoModel(user: user)
                    }
                }
            }
        }
        .font(.system(size: 14))
        .disabled(viewModel.isLoading)
    }
    
}

struct UserInfoModel: Identifiable {
    let id = UUID()
    let user: UserInfo
}
