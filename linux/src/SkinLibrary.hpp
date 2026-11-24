#pragma once
// Imported `.kurocat` skins live in $XDG_DATA_HOME/kurocat/skins (default ~/.local/share/kurocat/skins),
// one file per skin named <content-hash>.kurocat. Built-in coats are not stored here.
#include <algorithm>
#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <dirent.h>
#include <string>
#include <sys/stat.h>
#include <unistd.h>
#include <vector>
#include "../../shared/SkinSpec.hpp"

struct SkinLibrary {
    std::vector<SkinSpec> skins; // sorted by name

    static std::string dir() {
        const char* xdg = std::getenv("XDG_DATA_HOME");
        std::string base;
        if (xdg && xdg[0] == '/') base = xdg;
        else {
            const char* home = std::getenv("HOME");
            base = std::string(home ? home : "/tmp") + "/.local/share";
        }
        return base + "/kurocat/skins";
    }

    static bool ensureDir() {
        std::string d = dir();
        for (size_t i = 1; i <= d.size(); ++i) {
            if (i == d.size() || d[i] == '/') {
                std::string part = d.substr(0, i);
                if (mkdir(part.c_str(), 0755) != 0 && errno != EEXIST) return false;
            }
        }
        return true;
    }

    void reload() {
        skins.clear();
        DIR* d = opendir(dir().c_str());
        if (!d) return;
        while (dirent* e = readdir(d)) {
            std::string n = e->d_name;
            if (n.size() < 9 || n.compare(n.size() - 8, 8, ".kurocat") != 0) continue;
            SkinSpec s;
            std::string err;
            if (SkinSpec::loadFile(dir() + "/" + n, s, err)) skins.push_back(std::move(s));
            else std::fprintf(stderr, "KuroCat: skipping skin %s: %s\n", n.c_str(), err.c_str());
        }
        closedir(d);
        std::sort(skins.begin(), skins.end(), [](const SkinSpec& a, const SkinSpec& b) { return a.name < b.name; });
    }

    const SkinSpec* find(const std::string& id) const {
        for (const auto& s : skins) if (s.id == id) return &s;
        return nullptr;
    }

    // Validates `path`, copies it into the skins folder and returns the new skin's id.
    bool importFile(const std::string& path, std::string& idOut, std::string& error) {
        FILE* f = std::fopen(path.c_str(), "rb");
        if (!f) { error = "无法打开这个文件"; return false; }
        std::string bytes;
        char buf[65536];
        size_t n;
        while ((n = std::fread(buf, 1, sizeof buf, f)) > 0) {
            bytes.append(buf, n);
            if (bytes.size() > SkinSpec::MaxFileBytes) { std::fclose(f); error = "皮肤文件超过 2 MB 上限"; return false; }
        }
        std::fclose(f);
        SkinSpec spec;
        if (!SkinSpec::parse(bytes, spec, error)) return false;
        if (!ensureDir()) { error = "无法创建皮肤文件夹 " + dir(); return false; }
        std::string target = dir() + "/" + spec.id + ".kurocat";
        std::string tmp = target + ".tmp";
        FILE* o = std::fopen(tmp.c_str(), "wb");
        if (!o) { error = "无法写入皮肤文件夹 " + dir(); return false; }
        bool ok = std::fwrite(bytes.data(), 1, bytes.size(), o) == bytes.size();
        ok = (std::fclose(o) == 0) && ok;
        if (!ok || std::rename(tmp.c_str(), target.c_str()) != 0) { unlink(tmp.c_str()); error = "保存皮肤失败（磁盘已满或没有权限？）"; return false; }
        idOut = spec.id;
        reload();
        return true;
    }

    bool remove(const std::string& id) {
        if (id.empty() || id.find('/') != std::string::npos || id.find("..") != std::string::npos) return false;
        bool ok = unlink((dir() + "/" + id + ".kurocat").c_str()) == 0;
        reload();
        return ok;
    }
};
