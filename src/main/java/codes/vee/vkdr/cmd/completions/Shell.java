package codes.vee.vkdr.cmd.completions;

/**
 * Shells for which vkdr can generate and install completions.
 * Used as an @Option type so picocli renders ${COMPLETION-CANDIDATES} in help
 * and offers the values in the generated completion script.
 */
public enum Shell {
    bash,
    zsh
}
