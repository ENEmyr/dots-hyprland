//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules/common"
import "services"
import "modules/ii/sidebarLeft"

import QtQuick
import Quickshell

ShellRoot {
    id: root

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
    }

    LazyLoader {
        active: Config.ready
        component: SidebarLeft {}
    }
}
