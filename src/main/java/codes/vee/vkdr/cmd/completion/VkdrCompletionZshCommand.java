package codes.vee.vkdr.cmd.completion;

import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.io.PrintWriter;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "zsh", mixinStandardHelpOptions = true,
        description = {
                "print the zsh completion script to stdout",
                "Identical to the bash script: it self-enables bashcompinit under zsh.",
                "Try it in the current shell:  source <(vkdr completion zsh)",
                "Wire it up permanently with:  vkdr completion install"},
        exitCodeOnExecutionException = ExitCodes.COMPLETION_ZSH)
public class VkdrCompletionZshCommand implements Callable<Integer> {

    @CommandLine.Spec
    CommandLine.Model.CommandSpec spec;

    @Override
    public Integer call() {
        PrintWriter out = spec.commandLine().getOut();
        // print, not println: Windows line separators break sourcing
        out.print(CompletionSupport.generate(spec));
        out.print('\n');
        out.flush();
        return 0;
    }
}
