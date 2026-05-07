#include <unistd.h>

int main(int argc, char *argv[]) {
    char *args[] = {
        "/bin/bash",
        "/Users/[USERNAME]/bin/ftps_upload_event.sh",
        NULL
    };
    execv("/bin/bash", args);
    return 1;
}
