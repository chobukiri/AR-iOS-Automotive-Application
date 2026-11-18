import SwiftUI

// ══════════════════════════════════════════════════════════════════════════
// SCREEN 8 — GLOSSARY (Searchable Automotive Terms)
// ══════════════════════════════════════════════════════════════════════════

struct GlossaryView: View {
    @State private var searchText = ""
    @State private var expandedTerm: String? = nil
    @Environment(\.dismiss) var dismiss

    var filteredTerms: [GlossaryTerm] {
        if searchText.isEmpty { return glossaryTerms }
        return glossaryTerms.filter {
            $0.term.localizedCaseInsensitiveContains(searchText) ||
            $0.definition.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 8) {
                    // ── Top Bar ───────────────────────────────────────
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                        }
                        Spacer()
                        Text("GLOSSARY")
                            .font(AppFonts.screenTitle)
                            .foregroundColor(.white)
                            .tracking(0.5)
                        Spacer()
                        Spacer().frame(width: 40)
                    }
                    .padding(.horizontal, 4)

                    // ── Search Bar ────────────────────────────────────
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textHint)
                        TextField("Search terms...", text: $searchText)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.chip)
                            .stroke(AppColors.cardBorder, lineWidth: 0.5)
                    )
                    .cornerRadius(AppRadius.chip)
                    .padding(.horizontal, 12)

                    // ── Terms List ────────────────────────────────────
                    VStack(alignment: .leading, spacing: 16) {
                        let grouped = Dictionary(grouping: filteredTerms, by: { $0.category }).sorted { $0.key < $1.key }
                        
                        ForEach(grouped, id: \.key) { category, terms in
                            VStack(alignment: .leading, spacing: 0) {
                                // Category Header
                                Text(category.uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 14)
                                    .padding(.top, 14)
                                    .padding(.bottom, 6)
                                    .tracking(1.0)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(terms) { term in
                                        VStack(alignment: .leading, spacing: 0) {
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    expandedTerm = expandedTerm == term.id ? nil : term.id
                                                }
                                            }) {
                                                HStack {
                                                    Text(term.term)
                                                        .font(.system(size: 15, weight: .medium))
                                                        .foregroundColor(.white)
                                                    Spacer()
                                                    Image(systemName: expandedTerm == term.id ? "chevron.down" : "chevron.right")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white)
                                                }
                                                .padding(.vertical, 8)
                                                .contentShape(Rectangle())
                                            }
            
                                            if expandedTerm == term.id {
                                                Text(term.definition)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white)
                                                    .padding(.bottom, 8)
                                                    .lineSpacing(4)
                                                    .transition(.opacity)
                                            }
                                        }
                                        .overlay(
                                            Rectangle()
                                                .fill(AppColors.cardBorder.opacity(0.5))
                                                .frame(height: 0.5)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                        )
                                        .animation(.easeInOut(duration: 0.2), value: expandedTerm)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.bottom, 8)
                            }
                            .cardStyle()
                        }
                    }
                    .padding(.horizontal, 12)

                    if filteredTerms.isEmpty {
                        VStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.textDim)
                            Text("No matching terms found")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
