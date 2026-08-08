package codes.vee.vkdr.cmd.completion;

import codes.vee.vkdr.VkdrApplication;
import codes.vee.vkdr.cmd.common.ExitCodes;
import codes.vee.vkdr.cmd.completion.CompletionSupport.Change;
import picocli.CommandLine;

import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "write the completion script and wire it into your shell",
        exitCodeOnExecutionException = ExitCodes.COMPLETION_INSTALL)
public class VkdrCompletionInstallCommand implements Callable<Integer> {

    @CommandLine.Spec
    CommandLine.Model.CommandSpec spec;

    @CommandLine.Option(names = {"--shell"},
            description = "shell to configure: ${COMPLETION-CANDIDATES} (default: detected from $SHELL)")
    private Shell shell;

    @CommandLine.Option(names = {"--rc-file", "--rc_file"},
            description = "rc file to modify (default: ~/.bashrc or ${ZDOTDIR:-~}/.zshrc)")
    private String rcFile;

    @CommandLine.Option(names = {"--dir"},
            description = "install into this directory instead of auto-detecting one on the shell's search path")
    private String dir;

    @CommandLine.Option(names = {"--no-rc"},
            description = "only write the completion script, never touch an rc file")
    private boolean noRc;

    @CommandLine.Option(names = {"--dry-run"},
            description = "report what would change without writing anything")
    private boolean dryRun;

    @CommandLine.Option(names = {"-y", "--yes"},
            description = "do not prompt before modifying an rc file")
    private boolean assumeYes;

    @Override
    public Integer call() throws Exception {
        PrintWriter out = spec.commandLine().getOut();
        Shell target = CompletionSupport.detectShell(shell);
        Path script = CompletionSupport.scriptPath();

        say(out, "Shell: " + target + (shell == null ? " (detected from $SHELL)" : ""));

        // 1. The script itself always lives in ~/.vkdr/completions - vkdr-owned, safe to clobber.
        Change scriptChange = dryRun
                ? Change.UNCHANGED
                : CompletionSupport.writeScript(CompletionSupport.generate(spec), script);
        say(out, "Script: " + script + " (" + scriptChange.name().toLowerCase() + ")");

        if (noRc) {
            say(out, "Left rc files untouched (--no-rc). Source it yourself with:");
            say(out, "  . \"" + script + "\"");
            return 0;
        }

        // 2. Preferred: a directory the shell already searches, so no rc file is touched at all.
        //    Naming an rc file explicitly means the caller wants the rc path, so skip this.
        boolean rcRequested = rcFile != null && !rcFile.isEmpty();
        Path lazyDir = null;
        if (!rcRequested) {
            lazyDir = (dir != null && !dir.isEmpty())
                    ? Paths.get(CompletionSupport.expandHome(dir))
                    : lazyDirFor(target);
        }
        if (lazyDir != null) {
            Path payload = lazyDir.resolve(target == Shell.zsh ? "_vkdr" : "vkdr");
            if (!dryRun) {
                Files.createDirectories(lazyDir);
                CompletionSupport.writeScript(CompletionSupport.lazyPayload(target, script), payload);
            }
            say(out, "Installed: " + payload);
            say(out, "No rc file was modified - your shell already searches that directory.");
            say(out, "Open a new shell and press TAB after 'vkdr'.");
            return 0;
        }

        // 3. Fallback: a sentinel-guarded block in the rc file.
        Path rc = CompletionSupport.detectRcFile(target, rcFile);
        List<String> block = CompletionSupport.rcBlock(script);

        if (CompletionSupport.hasBlock(rc)) {
            Change c = CompletionSupport.upsertBlock(rc, block, dryRun);
            say(out, c == Change.UNCHANGED
                    ? "Completions already installed for " + target + " (" + rc + ") - nothing to do."
                    : "Updated the existing vkdr block in " + rc + ".");
            return 0;
        }

        say(out, "Will append to " + rc + ":");
        for (String line : block) {
            say(out, "  " + line);
        }
        if (dryRun) {
            say(out, "(--dry-run: nothing written)");
            return 0;
        }
        if (!confirm(out)) {
            say(out, "Aborted. Nothing was written to " + rc + ".");
            say(out, "Tip: 'vkdr completion install --no-rc' writes only the script.");
            return 0;
        }

        CompletionSupport.upsertBlock(rc, block, false);
        say(out, "Wired into " + rc + " (backup at " + rc + ".vkdr-bak)");
        say(out, "Open a new shell, or run:  . \"" + rc + "\"");
        return 0;
    }

    private Path lazyDirFor(Shell target) {
        Path t = CompletionSupport.lazyTarget(target);
        return t == null ? null : t.getParent();
    }

    /** Only prompts on a real terminal; an explicit `install` from a script proceeds. */
    private boolean confirm(PrintWriter out) {
        if (assumeYes || System.console() == null) {
            return true;
        }
        String answer = System.console().readLine("Proceed? [y/N] ");
        return answer != null && answer.trim().toLowerCase().startsWith("y");
    }

    private void say(PrintWriter out, String message) {
        if (!VkdrApplication.silentMode) {
            out.println(message);
        }
    }
}
