# mpv-manga-reader
mpv-manga-reader is a fairly hacky (but working) script to make mpv a usable manga reader (it also works great with LN scans). mpv is almost unrivalled at opening images and archives thanks to its high quality rendering, scaling, and shading capabilities, but there's no way internally for it to have something like a double page mode that people expect from manga reading software. Therefore, I created this script to help alleviate those shortcomings and hopefully convince you to finally abandon mcomix.

## Archive support
Reading archives with mpv is broken with 0.29 on many systems due to some locale nonsense. However this has been fixed in 0.30, so simply update to the next release or compile the master branch.

## Dependencies
mpv-manga-reader obviously depends on mpv. Using mpv built with libarchive support is also recommended. Due to the lack of decent image manipulating libraries in lua, I decided to instead make several shell calls instead. Here is a list of everything you will need in your path.

* `7z` (p7zip)
* `convert` and `identify` (ImageMagick)
* `grep`
* `ls`
* `rm`
* `sed`
* `sleep`
* `sort`
* `tar`
* `zip` and `zipinfo`

In theory, this can work on Windows however all of the path/shell stuff is written specifically with \*nix in mind. Since I do not own a Windows machine, there is no way I can test it. However, PRs for Windows support are welcome.

## Usage
Just place `manga-reader.lua` in your scripts directory and then load up a directory of images or an archive. ImageMagick's `identify` command is used to make sure that every file in the archive/directory is a valid image. If a non-image file is found, then it is simply ignored.

By default, starting mpv-manga-reader is bound to `y`. It will start in manga mode in single page mode and rebind some keys. Here are the defaults.

* toggle-manga-reader: `y`
* toggle-double-page: `d`
* toggle-continuous-mode: `c`
* toggle-manga-mode: `m`
* toggle-worker: `a`
* next-page: `LEFT`
* prev-page: `RIGHT`
* next-single-page: `Shift+LEFT`
* prev-single-page: `Shift+RIGHT`
* skip-forward: `Ctrl+LEFT`
* skip-backward: `Ctrl+RIGHT`
* first-page: `HOME`
* last-page: `END`
* pan-up: `UP`
* pan-down: `DOWN`
* jump-page-mode: `/`
* jump-page-go: `ENTER`
* jump-page-quit: `ctrl+[`

Keybindings can all be changed in input.conf in the usual way (i.e. `key script-message function-name`). If manga mode is false, then the direction keys of the `next-page` and `prev-page` functions are reversed (i.e. `next-page` becomes `RIGHT` and so on).

## jump-page
The `jump-page` functions work a little bit differently than the rest of the reader. Pressing `jump-page-mode` will do some key rebinds and then prompt the user with a message asking which page to move to. Simply press any combination of numbers followed by `jump-page-go` to move to the desired page. If the entered number is out of range, a message will be displayed. Either way, `jump-page-mode` will be ended. You can use `jump-page-quit` to quit `jump-page-mode` at any time.

## manga-worker
Another script that may be of interest is the `manga-worker.lua` script. Since stitching images together (for continuous and double page mode) can be slow, the manga-worker script does this for you in the background on a separate thread (thanks to mpv automatically multithreading scripts). Simply place it in your scripts directory, and it will start when the manga-reader is started. By default, the script will stitch pages together for double page mode. If the reader is flipped to continuous mode, then the worker script will stitch pages for that instead. In either case, the script will stitch together as many pages as possible in the loaded directory or archive. Workers can be toggled off and on with the `toggle-worker` command.

You can also put multiple copies of the manga-worker script in the directory. Each script will stitch together the appropriate subset of the total amount of requested stitched pages (i.e. stitching N pages with x worker scripts means that each script stitches N/x pages). The only requirement for extra manga-worker scripts is that each copy needs to have `manga-worker` in their name (i.e. `manga-worker1.lua` is valid). Each script runs on its own thread, so don't put too many copies of the worker script or else your CPU and RAM will probably run into some issues.

## Configuration
`manga-reader.lua` and all copies of `manga-worker.lua` read configurations from `manga-reader.conf` in your `script-opts` directory. The format for the file is `foo=value`. Here are the available options and their defaults.

``auto_start``\
Defaults to `no`. Automatically start the reader if valid images are detected.

``continuous``\
Defaults to `no`. Tells the manga reader whether or not to start in continuous mode. This is mutually exclusive with double page mode.

``continuous_size``\
Defaults to `4`. This is the amount of pages stitched together for each chunk in continuous mode.

``double``\
Defaults to `no`. Tells the manga reader whether or not to start in double page mode. This is mutally exclusive with continuous mode.

``manga``\
Defaults to `yes`. Tells the manga reader whether or not to start in manga mode (i.e. read right-to-left or left-to-right).

``monitor_height``\
Defaults to `1080`. The height of the display. Apply any DPI scaling used to this value (i.e. a 4096x2160 display with a DPI scale of 2 should be set to 1080).

``monitor_width``\
Defaults to `1920`. The width of the display. Apply any DPI scaling used to this value (i.e. a 4096x2160 display with a DPI scale of 2 should be set to 1920).

``pages``\
Defaults to `-1`. Tells the manga-worker scripts how many pages ahead of the current loaded page to stitch together. `-1` means to stitch pages all the way to the end of the archive/directory. Set to a positive number if you want to stop at a certain point.

``pan_size``\
Defaults to 0.05`. Defines the magnitude of pan-up and pan-down.

``skip_size``\
Defaults to `10`. This is the interval used by the `skip-forward` and `skip-backward` functions.

``trigger_buffer``\
Defaults to 0.05. When in continuous mode, the manga reader attempts to be smart and change pages for you once a pan value goes past a certain amount (determined by the page dimensions and the vertical alignment). The trigger_buffer is an additional value added to this parameter. Basically, increasing the value will make it take longer for panning a page to change pages whereas decreasing does the opposite.

``worker``\
Defaults to `yes`. Tells the manga-reader to use manga-worker scripts if they are available.

## Notes
Quitting will call the `close_manga_reader` function and remove extraneous files and folders created from archive extraction and/or imagemagick.

## License
GPLv3
