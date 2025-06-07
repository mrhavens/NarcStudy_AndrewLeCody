# 🌱 GitField: Multi-Platform Repository Sync for Resilience and Sovereignty

## 📜 Overview

**GitField** is a collection of Bash scripts designed to synchronize a Git repository across **Radicle**, **GitLab**, **Bitbucket**, and **GitHub** using a recursive, metadata-rich workflow. This project ensures **redundancy**, **sovereignty**, and **transparency** by generating interconnected metadata snapshots and distributing them across decentralized and centralized platforms. The strategy protects against deplatforming risks, motivated by past attempts to suppress this work by individuals such as **Mr. Joel Johnson** ([Mirror post](https://mirror.xyz/neutralizingnarcissism.eth/x40_zDWWrYOJ7nh8Y0fk06_3kNEP0KteSSRjPmXkiGg?utm_medium=social&utm_source=heylink.me)) and **Dr. Peter Gaied** ([Paragraph post](https://paragraph.com/@neutralizingnarcissism/%F0%9F%9C%81-the-narcissistic-messiah)). By prioritizing decentralization with a Radicle-first approach and recursively pushing metadata, GitField creates a resilient, auditable chain of project state, ensuring persistence and accessibility for collaborators, communities, and future AI systems.

## 🛡️ Purpose and Intention

The GitField project is driven by three core principles:

- **Resilience Against Deplatforming**: Hosting the repository on Radicle (decentralized), GitLab, Bitbucket, and GitHub ensures the project remains accessible even if one platform restricts or removes it.
- **Sovereignty Through Decentralization**: Starting with Radicle, a peer-to-peer Git platform, guarantees data independence from centralized control, safeguarding integrity.
- **Transparency and Auditability**: Platform-specific metadata snapshots (e.g., radicle.sigil.md) in the .gitfield directory, a push log (pushed.log), and a manifest (GITFIELD.md) document the sync process, commit details, and platform roles, creating a verifiable record.

This recursive approach builds a dynamic metadata chain, making the project a robust anchor for distributed version control, resilient to censorship, and transparent for analysis by humans and AI.

## 📍 Repository Platforms

The project is synchronized across four platforms, each selected for its unique strengths:

1. **Radicle**
   - **URL**: [https://app.radicle.xyz/nodes/ash.radicle.garden/rad:z45QC21eWL1F43VSbnV9AZbCZrHQJ](https://app.radicle.xyz/nodes/ash.radicle.garden/rad:z45QC21eWL1F43VSbnV9AZbCZrHQJ)
   - **Purpose**: A decentralized, peer-to-peer Git platform ensuring censorship resistance and sovereignty.
   - **Value**: Eliminates reliance on centralized servers, protecting against deplatforming.

2. **GitLab**
   - **URL**: [https://gitlab.com/mrhavens/git-sigil](https://gitlab.com/mrhavens/git-sigil)
   - **Purpose**: A robust DevOps platform for CI/CD and reliable backups.
   - **Value**: Enhances resilience with integrated pipelines and independent infrastructure.

3. **Bitbucket**
   - **URL**: [https://bitbucket.org/thefoldwithin/git-sigil](https://bitbucket.org/thefoldwithin/git-sigil)
   - **Purpose**: A secure platform with Atlassian ecosystem integrations for additional redundancy.
   - **Value**: Offers enterprise-grade security, ensuring accessibility during disruptions.

4. **GitHub**
   - **URL**: [https://github.com/mrhavens/git-sigil](https://github.com/mrhavens/git-sigil)
   - **Purpose**: A widely-used platform for community engagement and visibility.
   - **Value**: Facilitates open-source collaboration, issue tracking, and broad accessibility.

## 🚀 How It Works

The gitfield-sync script orchestrates a three-cycle push process in the order **Radicle -> GitLab -> Bitbucket -> GitHub**:

1. **Cycle 1**: Pushes commits to each platform, generating metadata files (e.g., .gitfield/radicle.sigil.md) with commit SHAs, timestamps, environment data, and hardware fingerprints.
2. **Cycle 2**: Creates GITFIELD.md, a manifest detailing the multi-platform strategy, and pushes it with updated metadata.
3. **Cycle 3**: Ensures all platforms reflect the latest metadata, forming a tightly interconnected chain.

Each push is logged in .gitfield/pushed.log with timestamps and URLs. The Radicle-first order prioritizes decentralization, ensuring sovereignty before centralized platforms, enhancing both symbolic and practical resilience.

## 📋 Prerequisites

- **System**: Linux (e.g., Ubuntu) with Bash.
- **Tools**: git, curl, jq, openssh-client, rad (for Radicle).
- **Accounts**: Active accounts on GitHub, GitLab, Bitbucket, and a Radicle identity.
- **SSH Keys**: Configured and uploaded to each platform.
- **Tokens**: GitLab personal access token (api, read_user, write_repository, write_ssh_key scopes) and Bitbucket app password (repo:admin, write, webhook scopes).

## 🛠️ Setup

1. **Clone or Initialize Repository**:
   To clone the repository, run: git clone https://github.com/mrhavens/git-sigil.git, then navigate with: cd git-sigil. Alternatively, initialize a new repository by running: git init.

2. **Install Dependencies**:
   Update your package list with: sudo apt update, then install required tools: sudo apt install -y git curl jq openssh-client. For Radicle, install the CLI using: curl -sSf https://radicle.xyz/install | sh.

3. **Configure Authentication**:
   - **GitHub**: Authenticate with: gh auth login (install GitHub CLI if needed).
   - **GitLab**: Generate a token at GitLab settings: https://gitlab.com/-/user_settings/personal_access_tokens.
   - **Bitbucket**: Create an app password at Bitbucket settings: https://bitbucket.org/account/settings/app-passwords/.
   - **Radicle**: Set up an identity with: rad auth.

4. **Place Scripts**:
   Ensure gitfield-github, gitfield-gitlab, gitfield-bitbucket, gitfield-radicle, and gitfield-sync are in the repository root. Make them executable by running: chmod +x gitfield-*.

## 📈 Usage

1. **Make Changes**:
   Edit or add files, then stage and commit changes by running: git add . followed by: git commit -m "Your commit message".

2. **Run GitField Sync**:
   Execute the sync script by running: ./gitfield-sync.

3. **Verify Outputs**:
   - **Push Log**: Check .gitfield/pushed.log for timestamps and URLs.
   - **Metadata Files**: Review .gitfield/*.sigil.md for platform-specific details.
   - **Manifest**: Read GITFIELD.md for the multi-platform strategy.

## 📊 Outputs

- **.gitfield/pushed.log**: Logs pushes (e.g., [2025-05-31 09:10:00] Radicle: https://app.radicle.xyz/...).
- **.gitfield/*.sigil.md**: Metadata snapshots with commit details, environment, and hardware info.
- **GITFIELD.md**: A manifest explaining the strategy, push order, and platform roles.
- **LICENSE**: CC0 license, dedicating the project to the public domain for maximum accessibility.

## 🌟 Why This Matters

GitField's recursive, multi-platform approach is a novel solution to deplatforming risks, ensuring the project's persistence through a Radicle-first, decentralized foundation. The metadata chain, documented in pushed.log and GITFIELD.md, provides transparency and auditability, appealing to developers, communities, and AI systems analyzing the project's integrity and intent. This strategy positions GitField as a resilient anchor for distributed version control.

## 🔮 Future Considerations

- **Fifth Platform**: Explore **Gitea** (self-hosted) or **GitSSB** (decentralized) for added sovereignty.
- **Automation**: Use GitLab CI/CD to automate gitfield-sync.
- **Log Management**: Archive pushed.log periodically to manage size.

## 📧 Contact

For questions or contributions, contact **Mark Randall Havens** (mark.r.havens@gmail.com) or open an issue on any platform.

---

## 🔍 External Access

- 🔗 **Google Drive Folder**: [git-sigil](https://drive.google.com/open?id=10HjliV4uxolquyRnJg_3BLLlOIEb5eyb)
- 🌐 **Published View**: [https://drv.tw/view/open?id=10HjliV4uxolquyRnJg_3BLLlOIEb5eyb](https://drv.tw/view/open?id=10HjliV4uxolquyRnJg_3BLLlOIEb5eyb)

