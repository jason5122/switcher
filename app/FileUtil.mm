#import "FileUtil.hh"

const char* resource_path(const std::string& name) {
    NSString* path = [[NSBundle mainBundle]
        pathForResource:[NSString stringWithUTF8String:name.c_str()]
                 ofType:nil];
    return [path fileSystemRepresentation];
}

char* read_file(const std::string& name) {
    struct stat statbuf;
    FILE* fh;
    char* source;

    fh = fopen(name.c_str(), "r");
    if (fh == 0) return 0;

    stat(name.c_str(), &statbuf);
    source = (char*)malloc(statbuf.st_size + 1);
    fread(source, statbuf.st_size, 1, fh);
    source[statbuf.st_size] = '\0';
    fclose(fh);

    return source;
}
