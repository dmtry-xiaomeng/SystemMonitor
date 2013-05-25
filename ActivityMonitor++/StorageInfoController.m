//
//  StorageInfoController.m
//  ActivityMonitor++
//
//  Created by st on 24/05/2013.
//  Copyright (c) 2013 st. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "AMLog.h"
#import "AMUtils.h"
#import "StorageInfoController.h"

@interface StorageInfoController()
@property (strong, nonatomic) StorageInfo *storageInfo;

- (CGFloat)getTotalSpace;
- (CGFloat)getUsedSpace;
- (CGFloat)getFreeSpace;
- (NSUInteger)getSongCount;
- (NSUInteger)getTotalSongSize;
- (NSUInteger)updatePictureCount;
- (NSUInteger)updateVideoCount;

- (void)assetsLibraryDidChange:(NSNotification*)notification;
@end

@implementation StorageInfoController
@synthesize delegate;

@synthesize storageInfo;

#pragma mark - public

- (StorageInfo*)getStorageInfo
{
    self.storageInfo = [[StorageInfo alloc] init];
    
    self.storageInfo.totalSapce = [self getTotalSpace];
    self.storageInfo.usedSpace = [self getUsedSpace];
    self.storageInfo.freeSpace = [self getFreeSpace];
    self.storageInfo.songCount = [self getSongCount];
    self.storageInfo.totalSongSize = [self getTotalSongSize];
    
    [self updatePictureCount];
    [self updateVideoCount];
    
    return self.storageInfo;
}

#pragma mark - private

- (CGFloat)getTotalSpace
{    
    NSError         *error = nil;
    NSArray         *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary    *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:paths.lastObject error:&error];

    if (dictionary)
    {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemSize];
        return B_TO_KB([fileSystemSizeInBytes unsignedLongLongValue]);
    }
    else
    {
        AMWarn(@"%s: attributesOfFileSystemForPat() has failed: %@", __PRETTY_FUNCTION__, error.description);
        return 0.0f;
    }
}

- (CGFloat)getUsedSpace
{
    NSError         *error = nil;
    NSArray         *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary    *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:paths.lastObject error:&error];
    
    if (dictionary)
    {
        NSNumber *fileSystemSize = [dictionary objectForKey:NSFileSystemSize];
        NSNumber *fileSystemFreeSize = [dictionary objectForKey:NSFileSystemFreeSize];
        uint64_t usedSize = [fileSystemSize unsignedLongLongValue] - [fileSystemFreeSize unsignedLongLongValue];
        return B_TO_KB(usedSize);
    }
    else
    {
        AMWarn(@"%s: attributesOfFileSystemForPat() has failed: %@", __PRETTY_FUNCTION__, error.description);
        return 0.0f;
    }
}

- (CGFloat)getFreeSpace
{
    NSError         *error = nil;
    NSArray         *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary    *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:paths.lastObject error:&error];
    
    if (dictionary)
    {
        NSNumber *fileSystemFreeSize = [dictionary objectForKey:NSFileSystemFreeSize];
        return B_TO_KB([fileSystemFreeSize unsignedLongLongValue]);
    }
    else
    {
        AMWarn(@"%s: attributesOfFileSystemForPat() has failed: %@", __PRETTY_FUNCTION__, error.description);
        return 0.0f;
    }
}

- (NSUInteger)getSongCount
{
    return [[MPMediaQuery songsQuery] items].count;
}

- (NSUInteger)getTotalSongSize
{
    // TODO:
    /*
    NSUInteger size = 0;
    NSArray *songs = [[MPMediaQuery songsQuery] items];
    
    for (MPMediaItem *item in songs)
    {
        NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
        AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL: url options:nil];
        CMTime duration = songAsset.duration;
        float durationSeconds = CMTimeGetSeconds(duration);
        AVAssetTrack *track = [songAsset.tracks objectAtIndex:0];
        [track loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"estimatedDataRate"] completionHandler:^() { NSLog(@"%f", track.estimatedDataRate); }];
        float dr = track.estimatedDataRate;
        NSLog(@"dr: %f", dr);
    }
    */
    return 0;
}

- (NSUInteger)updatePictureCount
{
    self.storageInfo.pictureCount = 0;
    self.storageInfo.totalPictureSize = 0;
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
            if (asset)
            {
                NSString *type = [asset  valueForProperty:ALAssetPropertyType];
                if ([type isEqualToString:ALAssetTypePhoto])
                {
                    self.storageInfo.pictureCount++;
                    
                    ALAssetRepresentation *rep = [asset defaultRepresentation];
                    self.storageInfo.totalPictureSize += B_TO_KB(rep.size);
                }
            }
            else
            {
                [self.delegate storageInfoUpdated];
            }
        }];
    } failureBlock:^(NSError *error) {
        AMWarn(@"%s: Failed to enumerate asset groups: %@", __PRETTY_FUNCTION__, error.description);
    }];
    
    return 0;
}

- (NSUInteger)updateVideoCount
{
    self.storageInfo.videoCount = 0;
    self.storageInfo.totalVideoSize = 0;
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    
    [assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group setAssetsFilter:[ALAssetsFilter allVideos]];
        [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
            if (asset)
            {
                NSString *type = [asset  valueForProperty:ALAssetPropertyType];
                if ([type isEqualToString:ALAssetTypeVideo])
                {
                    self.storageInfo.videoCount++;
                    
                    ALAssetRepresentation *rep = [asset defaultRepresentation];
                    self.storageInfo.totalVideoSize += B_TO_KB(rep.size);
                }
            }
            else
            {
                [self.delegate storageInfoUpdated];
            }
        }];
    } failureBlock:^(NSError *error) {
        AMWarn(@"%s: Failed to enumerate asset groups: %@", __PRETTY_FUNCTION__, error.description);
    }];
    
    return 0;
}

- (void)assetsLibraryDidChange:(NSNotification*)notification
{
    [self updatePictureCount];
    [self updateVideoCount];
}

@end