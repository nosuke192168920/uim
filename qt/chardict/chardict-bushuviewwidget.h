/*

Copyright (c) 2003-2007 uim Project http://code.google.com/p/uim/

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
3. Neither the name of authors nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

*/
#ifndef _BUSHU_VIEW_WIDGET_H_
#define _BUSHU_VIEW_WIDGET_H_

#include "chardict-qt.h"

#include <qwidget.h>
#include <qfont.h>
#include <qlistview.h>
#include <qsplitter.h>

class CharGridView;

class BushuViewWidget : public CharDictViewBase
{
    Q_OBJECT

public:
    BushuViewWidget( QWidget *parent = 0, const char *name = 0 );
    ~BushuViewWidget();

    void setFont( const QFont &font );

protected:
    void setupWidgets();
    void readDict();

    void writeConfig();
    void readConfig();

protected slots:
    void slotBushuSelected( QListViewItem * );

protected:
    QSplitter *m_mainSplitter;
    QListView *m_bushuListView;
    CharGridView *m_charGridView;
};

#endif /* Not def: _BUSHU_VIEW_WIDGET_H_ */
