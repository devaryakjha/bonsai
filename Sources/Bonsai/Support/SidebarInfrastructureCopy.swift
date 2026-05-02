enum SidebarInfrastructureCopy {
  static func worktreesTitle(count: Int) -> String {
    count == 0 ? "No linked worktrees" : "Linked worktrees"
  }

  static func remotesTitle(count: Int) -> String {
    count == 0 ? "No configured remotes" : "Configured remotes"
  }

  static func submodulesTitle(count: Int) -> String {
    count == 0 ? "No submodules" : "Repository submodules"
  }
}
