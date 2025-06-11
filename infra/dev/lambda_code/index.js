// lambda_code/pii_stripper/index.js
const zlib = require('zlib');
const AWS = require('aws-sdk');

const logs = new AWS.CloudWatchLogs();
const SANITIZED_LOG_GROUP_NAME = process.env.SANITIZED_LOG_GROUP_NAME;

exports.handler = async (event) => {
    const payload = Buffer.from(event.awslogs.data, 'base64');
    const decompressed = zlib.gunzipSync(payload);
    const logData = JSON.parse(decompressed.toString('utf8'));

    const sanitizedLogEvents = logData.logEvents.map(logEvent => {
        let message = logEvent.message;

        // --- Basic PII Redaction ---
        // Redact Email Addresses
        message = message.replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, '[EMAIL_REDACTED]');

        // Redact Phone Numbers
        message = message.replace(/\b(?:\d{3}[-.\s]?\d{3}[-.\s]?\d{4})\b/g, '[PHONE_REDACTED]');

        return { timestamp: logEvent.timestamp, message: message };
    });

    if (sanitizedLogEvents.length === 0) {
        return 'No log events to process.';
    }

    const logStreamName = logData.logStream;
    let sequenceToken;

    try {
        const describeResponse = await logs.describeLogStreams({
            logGroupName: SANITIZED_LOG_GROUP_NAME,
            logStreamNamePrefix: logStreamName
        }).promise();

        const stream = describeResponse.logStreams.find(s => s.logStreamName === logStreamName);
        if (stream) {
            sequenceToken = stream.uploadSequenceToken;
        } else {
            await logs.createLogStream({
                logGroupName: SANITIZED_LOG_GROUP_NAME,
                logStreamName: logStreamName
            }).promise();
        }
    } catch (e) {
        if (e.code !== 'ResourceAlreadyExistsException') {
            console.error('Error getting/creating log stream:', e);
            throw e;
        }
    }

    try {
        const putParams = {
            logGroupName: SANITIZED_LOG_GROUP_NAME,
            logStreamName: logStreamName,
            logEvents: sanitizedLogEvents,
        };
        if (sequenceToken) {
            putParams.sequenceToken = sequenceToken;
        }

        await logs.putLogEvents(putParams).promise();
        return 'Sanitized logs processed successfully.';

    } catch (e) {
        console.error('Error putting sanitized log events:', e);
        throw e;
    }
};