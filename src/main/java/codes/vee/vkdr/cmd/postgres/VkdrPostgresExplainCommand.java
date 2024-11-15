package codes.vee.vkdr.cmd.postgres;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain Postgres install formulas",
        exitCodeOnExecutionException = ExitCodes.POSTGRES_EXPLAIN)
public class VkdrPostgresExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("postgres/explain");
    }
}
