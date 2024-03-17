package codes.vee.vkdr;

import picocli.CommandLine;

public class CommandUtils {
    public static String getFullCommandName(CommandLine.Model.CommandSpec spec) {
        StringBuilder commandName = new StringBuilder(spec.name());
        while (spec.parent() != null) {
            spec = spec.parent();
            commandName.insert(0, spec.name() + " ");
        }
        return commandName.toString().trim(); // Trim to remove the trailing space
    }
}
