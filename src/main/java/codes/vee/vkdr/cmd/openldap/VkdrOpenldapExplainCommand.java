package codes.vee.vkdr.cmd.openldap;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain OpenLDAP install formulas",
        exitCodeOnExecutionException = ExitCodes.OPENLDAP_EXPLAIN)
public class VkdrOpenldapExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("openldap/explain");
    }
}
