import SwiftUI

// MARK: - Section model and parser

struct LegalDocumentSection: Identifiable {
    let id: String
    let number: String
    let title: String
    let body: String
}

enum LegalDocumentParser {
    /// Section separator: newline, spaces, em dash, newline (so title "X — Y" is not split).
    private static let sectionSeparator = "\n        —\n"

    /// Splits full document string into intro (metadata) and sections.
    static func parse(_ content: String) -> (intro: String, sections: [LegalDocumentSection]) {
        let blocks = content
            .components(separatedBy: sectionSeparator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !blocks.isEmpty else {
            return (content, [])
        }
        let intro = blocks[0]
        var sections: [LegalDocumentSection] = []
        for block in blocks.dropFirst() {
            guard let firstNewline = block.firstIndex(of: "\n") else {
                if let section = parseSectionBlock(block) { sections.append(section) }
                continue
            }
            let firstLine = String(block[..<firstNewline]).trimmingCharacters(in: .whitespaces)
            let rest = String(block[block.index(after: firstNewline)...]).trimmingCharacters(in: .whitespaces)
            if let section = parseSectionLine(firstLine, body: rest) {
                sections.append(section)
            }
        }
        return (intro, sections)
    }

    private static func parseSectionLine(_ firstLine: String, body: String) -> LegalDocumentSection? {
        let pattern = #"^(\d+)[.\s]+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: firstLine, range: NSRange(firstLine.startIndex..., in: firstLine)) else {
            return nil
        }
        let num = (firstLine as NSString).substring(with: match.range(at: 1))
        let tit = (firstLine as NSString).substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
        return LegalDocumentSection(id: "section-\(num)", number: num, title: tit, body: body)
    }

    private static func parseSectionBlock(_ singleLine: String) -> LegalDocumentSection? {
        parseSectionLine(singleLine, body: "")
    }
}

// MARK: - Legal search bar

struct LegalSearchBar: View {
    let placeholder: String
    @Binding var query: String
    var palette: ThemePalette

    var body: some View {
        HStack(spacing: Theme.spaceS) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(palette.mutedText)
            TextField(placeholder, text: $query)
                .font(.themeBody())
                .foregroundStyle(palette.text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(palette.mutedText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.spaceM)
        .padding(.vertical, Theme.spaceS + 2)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusSmall)
                .fill(palette.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusSmall)
                .stroke(palette.border.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Table of contents (collapsible)

struct LegalTOC: View {
    let sections: [LegalDocumentSection]
    @Binding var isExpanded: Bool
    var onJump: (String) -> Void
    var palette: ThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: Theme.spaceS) {
                    Text("Contents")
                        .font(.themeHeadline())
                        .foregroundStyle(palette.text)
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.mutedText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Theme.spaceS)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(sections) { section in
                        Button {
                            onJump(section.id)
                        } label: {
                            HStack(alignment: .top, spacing: Theme.spaceS) {
                                Text("\(section.number).")
                                    .font(.themeCaptionMedium())
                                    .foregroundStyle(palette.mutedText)
                                    .frame(width: 20, alignment: .leading)
                                Text(section.title)
                                    .font(.themeCallout())
                                    .foregroundStyle(palette.text)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, Theme.spaceS + 2)
                            .padding(.horizontal, Theme.spaceS)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, Theme.spaceXS)
            }
        }
        .padding(Theme.spaceM)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusSmall)
                .fill(palette.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusSmall)
                .stroke(palette.border.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Legal document screen (full redesign)

struct LegalDocumentScreen: View {
    let title: String
    let content: String
    @Environment(\.themeManager) private var themeManager
    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery = ""
    @State private var tocExpanded = true

    private var parsed: (intro: String, sections: [LegalDocumentSection]) {
        LegalDocumentParser.parse(content)
    }

    private var filteredSections: [LegalDocumentSection] {
        let sections = parsed.sections
        let q = searchQuery.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return sections }
        return sections.filter {
            $0.title.localizedCaseInsensitiveContains(q) || $0.body.localizedCaseInsensitiveContains(q)
        }
    }

    private var isFiltering: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var fullTextForCopy: String {
        content
    }

    var body: some View {
        let palette = themeManager.currentPalette
        let sections = parsed.sections
        let displaySections = isFiltering ? filteredSections : sections
        VStack(spacing: 0) {
            header(palette: palette)
            searchBar(palette: palette)
            if isFiltering {
                searchSummaryBar(displaySections: displaySections, palette: palette)
            }
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: Theme.spaceL) {
                        introCard(intro: parsed.intro, palette: palette)
                        LegalTOC(sections: sections, isExpanded: $tocExpanded, onJump: { id in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(id, anchor: .top)
                            }
                        }, palette: palette)
                        quickActionsRow(palette: palette)
                        if isFiltering && displaySections.isEmpty {
                            Text("No matches for “\(searchQuery)”")
                                .font(.themeCallout())
                                .foregroundStyle(palette.mutedText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Theme.spaceM)
                        }
                        ForEach(displaySections) { section in
                            sectionCard(section: section, palette: palette)
                                .id(section.id)
                        }
                    }
                    .padding(.horizontal, Theme.spaceM)
                    .padding(.top, Theme.spaceM)
                    .padding(.bottom, Theme.spaceXXL)
                }
            }
            .background(palette.background)
        }
        .background(palette.background)
    }

    private func searchSummaryBar(displaySections: [LegalDocumentSection], palette: ThemePalette) -> some View {
        HStack(spacing: Theme.spaceS) {
            Text("\(displaySections.count) section\(displaySections.count == 1 ? "" : "s")")
                .font(.themeCaption())
                .foregroundStyle(palette.mutedText)
            Spacer()
        }
        .padding(.horizontal, Theme.spaceM)
        .padding(.bottom, Theme.spaceXS)
    }

    private func header(palette: ThemePalette) -> some View {
        ZStack {
            LinearGradient(
                colors: [palette.primaryGradientStart, palette.primaryGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 0) {
                HStack(spacing: Theme.spaceM) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.themeHeadline())
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.spaceL)
                            .padding(.vertical, Theme.spaceS)
                            .background(Capsule().fill(.white.opacity(0.25)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Theme.spaceM)
                .padding(.vertical, Theme.spaceM)
            }
            .background(
                LinearGradient(
                    colors: [palette.primaryGradientStart.opacity(0.95), palette.primaryGradientEnd.opacity(0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .overlay(
            Rectangle()
                .fill(palette.border.opacity(0.15))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private func searchBar(palette: ThemePalette) -> some View {
        VStack(spacing: 0) {
            LegalSearchBar(placeholder: "Search this policy…", query: $searchQuery, palette: palette)
                .padding(.horizontal, Theme.spaceM)
                .padding(.vertical, Theme.spaceS)
        }
        .background(palette.background)
    }

    private func introCard(intro: String, palette: ThemePalette) -> some View {
        let lines = intro.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let titleLine = lines.first ?? ""
        let metaLines = lines.dropFirst().prefix(4).joined(separator: "\n")
        return VStack(alignment: .leading, spacing: Theme.spaceS) {
            Text(titleLine)
                .font(.themeTitleSmall())
                .foregroundStyle(palette.text)
            if !metaLines.isEmpty {
                Text(metaLines)
                    .font(.themeCaption())
                    .foregroundStyle(palette.mutedText)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.spaceM)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(palette.card)
                .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        )
    }

    private func quickActionsRow(palette: ThemePalette) -> some View {
        HStack(spacing: Theme.spaceM) {
            Button {
                UIPasteboard.general.string = fullTextForCopy
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.themeCallout())
                    .foregroundStyle(palette.brandTint)
            }
            .buttonStyle(.plain)
            ShareLink(item: fullTextForCopy, subject: Text(title)) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.themeCallout())
                    .foregroundStyle(palette.brandTint)
            }
            Spacer()
        }
        .padding(.vertical, Theme.spaceS)
    }

    private func sectionCard(section: LegalDocumentSection, palette: ThemePalette) -> some View {
        VStack(alignment: .leading, spacing: Theme.spaceS) {
            Text("\(section.number). \(section.title)")
                .font(.themeHeadline())
                .foregroundStyle(palette.text)
            if !section.body.isEmpty {
                Text(section.body)
                    .font(.themeBody())
                    .foregroundStyle(palette.text)
                    .lineSpacing(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.spaceM)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                .fill(palette.card)
                .shadow(color: Theme.cardShadow().color, radius: Theme.cardShadow().radius, y: Theme.cardShadow().y)
        )
    }
}
