package codes.vee.vkdr.cmd.postgres;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "dropdb", mixinStandardHelpOptions = true,
        description = "drops a database and its associated secrets in Kubernetes",
        exitCodeOnExecutionException = ExitCodes.POSTGRES_DROP_DB)
public class VkdrPostgresDropDBCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"-d","--database"},
    required = true,
    description = "Database name to drop")
    private String database_name;

    @CommandLine.Option(names = {"-u","--user"},
    defaultValue = "",
    description = "Database user/role name to remove")
    private String user_name;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("postgres/dropdb", database_name, user_name);
    }
}
