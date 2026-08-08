package codes.vee.vkdr.cmd.completions;

import codes.vee.vkdr.VkdrApplication;
import codes.vee.vkdr.cmd.common.ExitCodes;
import codes.vee.vkdr.cmd.completions.CompletionsSupport.Change;
import picocli.CommandLine;

import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "uninstall", mixinStandardHelpOptions = true,
        description = "remove vkdr completions from your shell",
        exitCodeOnExecutionException = ExitCodes.COMPLETIONS_UNINSTALL)
public class VkdrCompletionsUninstallCommand implements Callable<Integer> {

    @CommandLine.Spec
    CommandLine.Model.CommandSpec spec;

    @CommandLine.Option(names = {"--shell"},
            description = "shell to clean up: ${COMPLETION-CANDIDATES} (default: detected from $SHELL)")
    private Shell shell;

    @CommandLine.Option(names = {"--rc-file", "--rc_file"},
            description = "rc file to clean (default: ~/.bashrc or ${ZDOTDIR:-~}/.zshrc)")
    private String rcFile;

    @CommandLine.Option(names = {"--all"},
            description = "clean every known rc file, not just the one for the detected shell")
    private boolean all;

    @CommandLine.Option(names = {"--purge"},
            description = "also delete the generated script from ~/.vkdr/completions")
    private boolean purge;

    @CommandLine.Option(names = {"--dry-run"},
            description = "report what would change without writing anything")
    private boolean dryRun;

    @Override
    public Integer call() throws Exception {
        PrintWriter out = spec.commandLine().getOut();
        boolean removedAnything = false;

        if (all) {
            for (Shell s : Shell.values()) {
                removedAnything |= clean(out, CompletionsSupport.detectRcFile(s, null));
            }
        } else {
            Shell target = CompletionsSupport.detectShell(shell);
            removedAnything = clean(out, CompletionsSupport.detectRcFile(target, rcFile));
        }

        // The no-rc ("lazy") payloads, if a previous install placed any.
        for (Shell s : Shell.values()) {
            if (!all && shell != null && s != shell) {
                continue;
            }
            Path lazy = CompletionsSupport.lazyTarget(s);
            if (lazy != null && Files.exists(lazy)) {
                if (!dryRun) {
                    Files.delete(lazy);
                }
                say(out, "Removed " + lazy);
                removedAnything = true;
            }
        }
        Path wrapper = CompletionsSupport.zshWrapperPath();
        if (Files.exists(wrapper)) {
            if (!dryRun) {
                Files.delete(wrapper);
            }
            say(out, "Removed " + wrapper);
            removedAnything = true;
        }

        if (purge) {
            Path script = CompletionsSupport.scriptPath();
            if (Files.exists(script) && !dryRun) {
                Files.delete(script);
                say(out, "Removed " + script);
                removedAnything = true;
            }
        }

        if (!removedAnything) {
            say(out, "vkdr completions are not installed - nothing to do.");
        } else {
            say(out, "Open a new shell for the change to take effect.");
        }
        return 0;
    }

    private boolean clean(PrintWriter out, Path rc) throws Exception {
        Change c = CompletionsSupport.removeBlock(rc, dryRun);
        if (c == Change.REMOVED) {
            say(out, "Removed the vkdr block from " + rc);
            return true;
        }
        return false;
    }

    private void say(PrintWriter out, String message) {
        if (!VkdrApplication.silentMode) {
            out.println(message);
        }
    }
}
