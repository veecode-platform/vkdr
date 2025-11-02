package codes.vee.vkdr.cmd.postgres;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "pingdb", mixinStandardHelpOptions = true,
        description = "tests database connectivity by running a simple SELECT query",
        exitCodeOnExecutionException = ExitCodes.POSTGRES_PING_DB)
public class VkdrPostgresPingDBCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"-d","--database"},
    required = true,
    description = "Database name to test")
    private String database_name;

    @CommandLine.Option(names = {"-u","--user"},
    required = true,
    description = "Database user name for connection")
    private String user_name;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("postgres/pingdb", database_name, user_name);
    }
}
