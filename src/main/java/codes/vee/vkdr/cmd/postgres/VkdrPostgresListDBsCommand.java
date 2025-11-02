package codes.vee.vkdr.cmd.postgres;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "listdbs", mixinStandardHelpOptions = true,
        description = "lists all databases managed by the postgres cluster",
        exitCodeOnExecutionException = ExitCodes.POSTGRES_LIST_DBS)
public class VkdrPostgresListDBsCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"--json"},
    defaultValue = "false",
    description = "Output in JSON format")
    private boolean json;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("postgres/listdbs", String.valueOf(json));
    }
}
