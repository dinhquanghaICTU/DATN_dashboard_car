#pragma once

#include <QObject>
#include <QString>
#include <iostream>
#include <string>

class ConsoleInputWorker : public QObject {
    Q_OBJECT
public:
    explicit ConsoleInputWorker(QObject* parent = nullptr) : QObject(parent) {}

public slots:
    void run() {
        std::string line;
        while (std::getline(std::cin, line)) {
            QString input = QString::fromStdString(line).trimmed();
            if (!input.isEmpty()) {
                emit commandEntered(input);
            }
        }
    }

signals:
    void commandEntered(const QString& cmd);
};
