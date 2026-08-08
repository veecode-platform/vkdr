package codes.vee.vkdr.cmd.completions;

import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.io.PrintWriter;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "bash", mixinStandardHelpOptions = true,
        description = {
                "print the bash completion script to stdout",
                "Try it in the current shell:  source <(vkdr completions bash)",
                "Wire it up permanently with:  vkdr completions install"},
        exitCodeOnExecutionException = ExitCodes.COMPLETIONS_BASH)
public class VkdrCompletionsBashCommand implements Callable<Integer> {

    @CommandLine.Spec
    CommandLine.Model.CommandSpec spec;

    @Override
    public Integer call() {
        PrintWriter out = spec.commandLine().getOut();
        // print, not println: Windows line separators break sourcing
        out.print(CompletionsSupport.generate(spec));
        out.print('\n');
        out.flush();
        return 0;
    }
}
