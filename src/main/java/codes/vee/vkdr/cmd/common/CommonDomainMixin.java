package codes.vee.vkdr.cmd.common;

import picocli.CommandLine.Option;

public class CommonDomainMixin {
    @Option(names = {"-d", "--domain"},
            description = "Domain name to be used for the generated ingress (default: localhost)",
            defaultValue = "localhost",
            required = true)
    public String domain;

    @Option(names = {"-s", "--secure", "--enable_https"},
            description = "Enable HTTPS (default: false)",
            defaultValue = "false")
    public boolean enable_https;
}
