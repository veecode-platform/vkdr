package codes.vee.vkdr.cmd.completion;

import codes.vee.vkdr.VkdrApplication;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "status", mixinStandardHelpOptions = true,
        description = "report where shell completions are installed and whether they are current",
        exitCodeOnExecutionException = ExitCodes.COMPLETION_STATUS)
public class VkdrCompletionStatusCommand implements Callable<Integer> {

    @CommandLine.Spec
    CommandLine.Model.CommandSpec spec;

    @CommandLine.Option(names = {"--shell"},
            description = "shell to inspect: ${COMPLETION-CANDIDATES} (default: detected from $SHELL)")
    private Shell shell;

    @CommandLine.Option(names = {"--rc-file", "--rc_file"},
            description = "rc file to inspect (default: ~/.bashrc or ${ZDOTDIR:-~}/.zshrc)")
    private String rcFile;

    @Override
    public Integer call() throws Exception {
        PrintWriter out = spec.commandLine().getOut();
        Shell target = CompletionSupport.detectShell(shell);
        Path script = CompletionSupport.scriptPath();
        Path rc = CompletionSupport.detectRcFile(target, rcFile);
        Path wrapper = CompletionSupport.zshWrapperPath();

        Path lazy = CompletionSupport.lazyTarget(target);
        boolean scriptExists = Files.exists(script);
        boolean blockPresent = CompletionSupport.hasBlock(rc);
        boolean wrapperPresent = Files.exists(wrapper);
        boolean lazyPresent = lazy != null && Files.exists(lazy);
        boolean current = scriptExists && isCurrent(script);

        say(out, "shell:   " + target);
        say(out, "script:  " + script + (scriptExists ? (current ? " (present, current)" : " (present, STALE)") : " (missing)"));
        say(out, "rc file: " + rc + (blockPresent ? " (wired)" : " (no vkdr block)"));
        if (lazy != null) {
            say(out, "lazy:    " + lazy + (lazyPresent ? " (wired)" : " (not installed)"));
        }
        if (wrapperPresent) {
            say(out, "zsh:     " + wrapper + " (present)");
        }

        boolean wired = scriptExists && (blockPresent || wrapperPresent || lazyPresent);
        if (!wired) {
            say(out, "");
            say(out, "Not installed. Run: vkdr completion install");
        } else if (!current) {
            say(out, "");
            say(out, "The script is out of date. Run: vkdr init");
        }
        return wired ? 0 : 1;
    }

    /** The script is current when it matches what this binary would generate right now. */
    private boolean isCurrent(Path script) {
        try {
            String onDisk = Files.readString(script, StandardCharsets.UTF_8);
            String fresh = CompletionSupport.generate(spec);
            return onDisk.equals(fresh.endsWith("\n") ? fresh : fresh + "\n");
        } catch (Exception e) {
            return false;
        }
    }

    private void say(PrintWriter out, String message) {
        if (!VkdrApplication.silentMode) {
            out.println(message);
        }
    }
}
