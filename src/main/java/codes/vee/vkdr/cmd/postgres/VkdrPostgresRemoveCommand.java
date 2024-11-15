package codes.vee.vkdr.cmd.postgres;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove Postgres database",
        exitCodeOnExecutionException = ExitCodes.POSTGRES_REMOVE)
public class VkdrPostgresRemoveCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"-d","--delete", "--delete_storage", "--delete-storage"},
            defaultValue = "false",
            description = "delete postgres storage too after removal (default: false)")
    private boolean delete_storage;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("postgres/remove", String.valueOf(delete_storage));
    }
}
